//
//  ConditionSyncService.swift
//  kkhs2
//
//  Cloud sync for team-added conditions, backed by Supabase (Postgres +
//  its auto-generated REST API). The built-in conditions stay bundled in
//  the app; anything added or deleted from the Conditions tab is stored
//  in the `conditions` table so every device shows the same list.
//
//  Deliberately dependency-free: plain URLSession against PostgREST, so
//  no new Swift package has to be added to the Xcode project.
//
//  Schema (see supabase_setup.sql at the repo root):
//    conditions(id uuid pk, name text unique, description text,
//               procedures text, roles jsonb, created_at timestamptz)
//

import Foundation
import Combine

// MARK: - Row model matching the `conditions` table
struct CustomCondition: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let procedures: String
    let roles: [String]
    /// Raw ISO timestamp from PostgREST. Kept as a string to avoid
    /// date-decoding pitfalls with fractional seconds / offsets.
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, procedures, roles
        case createdAt = "created_at"
    }
}

// MARK: - Sync service
@MainActor
final class ConditionSyncService: ObservableObject {

    /// Supabase project "DhanvinPrakash's Project" (ap-northeast-2).
    private let tableURL = URL(string: "https://zpfjunyokfujucdoqnwv.supabase.co/rest/v1/conditions")!
    /// Publishable (anon) key — safe to embed in the app; actual access is
    /// governed by the table's RLS policies (see supabase_setup.sql).
    private let publishableKey = "sb_publishable_vmkjnO5VfOWOTeloOQMmOA_MBhgTwxM"

    @Published private(set) var customConditions: [CustomCondition] = []
    @Published private(set) var isSyncing = false
    @Published var lastError: String?

    private enum SyncError: LocalizedError {
        case http(Int, String)
        case nothingDeleted(String)

        var errorDescription: String? {
            switch self {
            case .nothingDeleted(let name):
                return "Couldn’t delete “\(name)” from the cloud. The database accepted the request but removed nothing — the `conditions` table most likely has no DELETE policy for the app’s key (row-level security)."
            case .http(let code, let body):
                if code == 409 { return "A condition with that name already exists in the cloud." }
                let snippet = body.prefix(160)
                return "Cloud sync failed (HTTP \(code)): \(snippet)"
            }
        }
    }

    // MARK: Request plumbing

    private func request(method: String, query: [URLQueryItem] = [], body: Data? = nil) -> URLRequest {
        var components = URLComponents(url: tableURL, resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 15
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func send(_ request: URLRequest, preferRepresentation: Bool = false) async throws -> Data {
        var request = request
        if preferRepresentation {
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw SyncError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    // MARK: Public API

    /// Re-fetches the custom condition list from Supabase.
    func loadConditions() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            let data = try await send(request(method: "GET", query: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "name.asc"),
            ]))
            customConditions = try JSONDecoder().decode([CustomCondition].self, from: data)
            lastError = nil
        } catch {
            lastError = friendly(error)
        }
    }

    /// Adds a condition to Supabase, then refreshes the cached list.
    @discardableResult
    func addCondition(name: String, description: String, procedures: String, roles: [String]) async -> CustomCondition? {
        let draft = CustomCondition(
            id: UUID(),
            name: name,
            description: description,
            procedures: procedures,
            roles: roles,
            createdAt: nil)
        do {
            let payload = try JSONEncoder().encode([draft])   // PostgREST inserts accept arrays
            let data = try await send(request(method: "POST", body: payload), preferRepresentation: true)
            let stored = try JSONDecoder().decode([CustomCondition].self, from: data)
            await loadConditions()
            return stored.first
        } catch {
            lastError = friendly(error)
            return nil
        }
    }

    /// Deletes the custom condition from Supabase. Returns true only if a row
    /// was actually removed.
    ///
    /// PostgREST answers 204/200 even when row-level security filters the
    /// DELETE down to zero rows, which previously looked like success: the row
    /// vanished locally and reappeared on the next sync. Asking for
    /// `return=representation` lets us see what was really deleted.
    @discardableResult
    func deleteCondition(named name: String) async -> Bool {
        do {
            let filter: URLQueryItem
            if let row = customConditions.first(where: { $0.name == name }) {
                filter = URLQueryItem(name: "id", value: "eq.\(row.id.uuidString.lowercased())")
            } else {
                filter = URLQueryItem(name: "name", value: "eq.\(name)")
            }
            let data = try await send(request(method: "DELETE", query: [filter]), preferRepresentation: true)
            let removed = (try? JSONDecoder().decode([CustomCondition].self, from: data)) ?? []
            guard !removed.isEmpty else { throw SyncError.nothingDeleted(name) }
            customConditions.removeAll { $0.name == name }
            lastError = nil
            return true
        } catch {
            lastError = friendly(error)
            return false
        }
    }

    private func friendly(_ error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
