//
//  CopilotContextStore.swift
//  kkhs2
//
//  Single source of truth the AI protocol copilot reads from. The copilot
//  itself never invents patient data — every screen that owns patient
//  inputs or checklist state publishes a snapshot here, and the copilot
//  is only ever given what's already visible in the app.
//

import SwiftUI
import Combine

struct APGARSnapshot: Equatable {
    var appearance: Int
    var pulse: Int
    var grimace: Int
    var activity: Int
    var respiration: Int
    var total: Int { appearance + pulse + grimace + activity + respiration }
}

/// A single checklist somewhere in the app (equipment, ECMO roles, manpower, etc).
struct CopilotChecklistSnapshot: Identifiable {
    let id: String
    var items: [(id: String, text: String, done: Bool)]

    var doneCount: Int { items.filter(\.done).count }
    var totalCount: Int { items.count }
    var missing: [String] { items.filter { !$0.done }.map(\.text) }
}

@MainActor
final class CopilotContextStore: ObservableObject {
    @Published var weightKg: Double = 0
    @Published var gaWeeks: Int = 0
    @Published var apgar: APGARSnapshot? = nil
    @Published var currentScreen: String = "Resuscitation"
    @Published private(set) var checklists: [String: CopilotChecklistSnapshot] = [:]

    /// Called by any view that owns a checklist. Safe to call on every
    /// state change — it's a cheap dictionary write.
    func publishChecklist(_ id: String, items: [(id: String, text: String, done: Bool)]) {
        checklists[id] = CopilotChecklistSnapshot(id: id, items: items)
    }

    /// Called when a checklist-owning view disappears, so the copilot
    /// doesn't keep referencing a checklist that's no longer on screen
    /// (e.g. a specific condition's manpower roles after navigating away).
    func removeChecklist(_ id: String) {
        checklists.removeValue(forKey: id)
    }
}
