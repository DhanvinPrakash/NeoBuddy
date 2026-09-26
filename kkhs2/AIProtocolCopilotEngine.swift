//
//  AIProtocolCopilotEngine.swift
//  kkhs2
//
//  The AI copilot is NOT a chatbot. It is a silent, structured protocol
//  copilot: given the app's current patient inputs, checklist state, and
//  pre-calculated protocol reference values, it returns one of six fixed
//  JSON response shapes. It never performs its own dose arithmetic and
//  never invents clinical facts — the app computes every number from the
//  same verified formulas used elsewhere in the UI (DrugDoses,
//  InfusionDrug, ECMOAppendixDrug, ettRowForGA) and hands those numbers
//  to the model as read-only reference data.
//
//  Backend priority:
//   1. Apple Intelligence (on-device, private, offline) via FoundationModels,
//      when the framework is available and the device/OS support it.
//   2. Gemini (cloud) as a fallback for devices that don't support Apple
//      Intelligence, using a user-supplied API key stored in the Keychain.
//   3. If neither is available, the copilot returns a low-confidence
//      response naming exactly what's missing, rather than staying silent
//      or guessing.
//

import Foundation
import Combine

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Modes

enum CopilotMode: String, CaseIterable, Identifiable, Codable {
    case nextStep         = "next_step"
    case doseCheck        = "dose_check"
    case checklistCheck   = "checklist_check"
    case handoverSummary  = "handover_summary"
    case missingItems     = "missing_items"
    case teachingMode     = "teaching_mode"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nextStep:        return "Next Step"
        case .doseCheck:       return "Dose Check"
        case .checklistCheck:  return "Checklist"
        case .handoverSummary: return "Handover"
        case .missingItems:    return "Missing"
        case .teachingMode:    return "Teach"
        }
    }

    var systemImage: String {
        switch self {
        case .nextStep:        return "arrow.turn.down.right"
        case .doseCheck:       return "syringe.fill"
        case .checklistCheck:  return "checklist"
        case .handoverSummary: return "doc.text.fill"
        case .missingItems:    return "exclamationmark.triangle.fill"
        case .teachingMode:    return "graduationcap.fill"
        }
    }

    /// Whether this mode benefits from a short free-text hint (e.g. which drug to check).
    var takesQuery: Bool {
        self == .doseCheck || self == .teachingMode
    }
}

// MARK: - Response contract (matches the required schema exactly)

struct CopilotResponse: Codable, Equatable {
    var mode: String
    var primary: String
    var secondary: String
    var items: [String]
    var warnings: [String]
    var missing: [String]
    var confidence: String   // "low" | "medium" | "high"
    var reference_ids: [String]

    static func placeholder(mode: CopilotMode, missing: [String]) -> CopilotResponse {
        CopilotResponse(mode: mode.rawValue, primary: "Copilot unavailable", secondary: "",
                         items: [], warnings: [], missing: missing, confidence: "low", reference_ids: [])
    }
}

// MARK: - Context payload sent to the model (read-only, app-computed)

struct CopilotContextPayload: Codable, Sendable {
    struct ChecklistPayload: Codable, Sendable {
        var name: String
        var done: Int
        var total: Int
        var missingItems: [String]
    }

    var weightKg: Double
    var gaWeeks: Int
    var apgar: [String: Int]?
    var apgarTotal: Int?
    var currentScreen: String
    var checklists: [ChecklistPayload]
    /// Pre-calculated protocol values (doses, ETT sizes, infusion rates),
    /// each already computed by the app from its verified formulas. The
    /// model must only reference these — never calculate its own.
    var protocolReference: [String]
}

// MARK: - Prompt construction & response parsing

enum CopilotPrompt {
    static let systemInstructions = """
    You are the AI feature inside a neonatal emergency app.
    Your role is to act as a silent, structured protocol copilot inside a floating window. You are not a chat assistant.

    Behavior:
    - Do not greet, explain, or chat.
    - Do not use conversational language unless absolutely required by the task.
    - Do not make up doses, steps, or clinical facts.
    - Use only the protocol data, patient inputs, checklist state, and reference information provided by the app.
    - If information is missing, return the missing fields.
    - If uncertain, set confidence to low.
    - Keep responses short, structured, and action-focused.

    What you do:
    - Tell the next best step.
    - Check a dose or protocol step.
    - Summarise the current case for handover.
    - Identify missing inputs or incomplete checklist items.
    - Support teaching mode only if explicitly requested.

    Supported modes: next_step, dose_check, checklist_check, handover_summary, missing_items, teaching_mode.

    Output format:
    Return JSON only, matching exactly this schema, with no markdown and no commentary outside the JSON:
    {"mode":"","primary":"","secondary":"","items":[],"warnings":[],"missing":[],"confidence":"low | medium | high","reference_ids":[]}

    Rules by mode:
    - next_step: return one next action only, in "primary". Base it only on the checklist and patient data provided.
    - dose_check: verify the dose/units against the values in protocolReference; never calculate your own. If the relevant value isn't in protocolReference, list it in "missing" and set confidence to low.
    - checklist_check: summarise completed vs incomplete items from the checklists provided, in "items".
    - handover_summary: a concise, copy-ready summary in "primary"/"secondary" — weight, GA, APGAR, checklist completion, nothing invented.
    - missing_items: list only what is missing or not yet done, in "missing".
    - teaching_mode: a minimal educational response, still structured and short, grounded only in the provided protocol data.

    UI assumptions:
    - The AI is shown in a small floating panel.
    - Keep answers compact enough for that panel.
    - No long paragraphs. No markdown. No extra commentary outside the JSON.

    Safety:
    - Never override protocol data.
    - Never infer a dose if the weight or rule is missing — the app supplies pre-calculated values in "protocolReference"; use only those, or report the gap in "missing" with confidence low.
    - Never recommend actions outside the provided protocol context.
    - Never pretend to be certain when you are not.

    The goal is fast bedside support, not conversation.
    """

    static func userPrompt(mode: CopilotMode, userQuery: String, context: CopilotContextPayload) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let contextJSON = (try? encoder.encode(context)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        return """
        mode: \(mode.rawValue)
        user_query: \(userQuery.isEmpty ? "(none)" : userQuery)
        app_context_json: \(contextJSON)

        Respond with JSON only, matching the schema in the system instructions.
        """
    }

    static func decode(_ raw: String, mode: CopilotMode) throws -> CopilotResponse {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "")
            text = text.replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Some models wrap the JSON in surrounding prose despite instructions;
        // fall back to extracting the outermost {...} block.
        if !text.hasPrefix("{"), let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            text = String(text[start...end])
        }
        guard let data = text.data(using: .utf8) else { throw CopilotError.parse }
        var decoded = try JSONDecoder().decode(CopilotResponse.self, from: data)
        if decoded.mode.isEmpty { decoded.mode = mode.rawValue }
        return decoded
    }
}

enum CopilotError: LocalizedError {
    case missingAPIKey, network(String), emptyResponse, parse

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:  return "Missing Gemini API key"
        case .network(let m): return m
        case .emptyResponse:  return "Empty model response"
        case .parse:          return "Could not parse model response"
        }
    }
}

// MARK: - Backend protocol

protocol CopilotBackend {
    var name: String { get }
    func run(mode: CopilotMode, userQuery: String, context: CopilotContextPayload) async throws -> CopilotResponse
}

// MARK: - Apple Intelligence backend (on-device, primary)
//
// The on-device model is small, and asking it to freehand valid JSON that
// matches our exact schema (as the Gemini path does) is the #1 reason this
// backend used to silently fail and fall through to Gemini on every call.
// FoundationModels' guided generation (@Generable / session.respond(to:
// generating:)) constrains decoding so the model can only produce output
// that already fits GuidedCopilotResponse's shape — no JSON parsing, no
// markdown-fence stripping, no "model wrapped it in prose" failures.

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GuidedCopilotResponse: Equatable {
    @Guide(description: "Echoes the requested copilot mode, e.g. next_step, dose_check")
    var mode: String
    @Guide(description: "The single most important line for the floating panel; empty if none")
    var primary: String
    @Guide(description: "Supporting detail for primary; empty if none")
    var secondary: String
    @Guide(description: "Short bullet items, e.g. checklist status lines")
    var items: [String]
    @Guide(description: "Short bullet warnings that need clinician attention")
    var warnings: [String]
    @Guide(description: "Names of fields or inputs that are missing/needed")
    var missing: [String]
    @Guide(description: "Confidence in this response", .anyOf(["low", "medium", "high"]))
    var confidence: String
    @Guide(description: "IDs from protocolReference this answer relied on")
    var reference_ids: [String]
}

@available(iOS 26.0, *)
final class AppleIntelligenceBackend: CopilotBackend {
    let name = "Apple Intelligence (on-device)"

    static var isAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        default:
            return false
        }
    }

    func run(mode: CopilotMode, userQuery: String, context: CopilotContextPayload) async throws -> CopilotResponse {
        let session = LanguageModelSession(instructions: CopilotPrompt.systemInstructions)
        let prompt = CopilotPrompt.userPrompt(mode: mode, userQuery: userQuery, context: context)
        let result = try await session.respond(to: prompt, generating: GuidedCopilotResponse.self)
        let g = result.content
        var response = CopilotResponse(
            mode: g.mode.isEmpty ? mode.rawValue : g.mode,
            primary: g.primary,
            secondary: g.secondary,
            items: g.items,
            warnings: g.warnings,
            missing: g.missing,
            confidence: g.confidence,
            reference_ids: g.reference_ids
        )
        if response.mode.isEmpty { response.mode = mode.rawValue }
        return response
    }
}
#endif

// MARK: - Gemini backend (cloud fallback)

final class GeminiBackend: CopilotBackend {
    let name = "Gemini (cloud fallback)"
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.model = model
    }

    func run(mode: CopilotMode, userQuery: String, context: CopilotContextPayload) async throws -> CopilotResponse {
        guard !apiKey.isEmpty else { throw CopilotError.missingAPIKey }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let prompt = CopilotPrompt.userPrompt(mode: mode, userQuery: userQuery, context: context)
        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": CopilotPrompt.systemInstructions]]],
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": Self.responseSchema,
                "temperature": 0.1
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Gemini request failed"
            throw CopilotError.network(message)
        }

        let decoded = try JSONDecoder().decode(GeminiResponseEnvelope.self, from: data)
        guard let text = decoded.candidates?.first?.content?.parts?.first?.text else {
            throw CopilotError.emptyResponse
        }
        return try CopilotPrompt.decode(text, mode: mode)
    }

    /// Gemini's structured-output schema (OpenAPI 3.0 subset), mirroring
    /// CopilotResponse exactly so the cloud fallback is just as reliably
    /// schema-conformant as the guided on-device Apple Intelligence path.
    private static let responseSchema: [String: Any] = [
        "type": "OBJECT",
        "properties": [
            "mode": ["type": "STRING"],
            "primary": ["type": "STRING"],
            "secondary": ["type": "STRING"],
            "items": ["type": "ARRAY", "items": ["type": "STRING"]],
            "warnings": ["type": "ARRAY", "items": ["type": "STRING"]],
            "missing": ["type": "ARRAY", "items": ["type": "STRING"]],
            "confidence": ["type": "STRING", "enum": ["low", "medium", "high"]],
            "reference_ids": ["type": "ARRAY", "items": ["type": "STRING"]]
        ],
        "required": ["mode", "primary", "confidence"]
    ]
}

private struct GeminiResponseEnvelope: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable { let text: String? }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}

// MARK: - Router

@MainActor
final class CopilotRouter: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    @Published private(set) var lastBackendUsed: String = ""

    func run(mode: CopilotMode, userQuery: String, context: CopilotContextPayload) async -> CopilotResponse {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), AppleIntelligenceBackend.isAvailable {
            do {
                let backend = AppleIntelligenceBackend()
                let result = try await backend.run(mode: mode, userQuery: userQuery, context: context)
                lastBackendUsed = backend.name
                return result
            } catch {
                // Fall through to Gemini rather than failing outright.
            }
        }
        #endif

        if let key = GeminiConfig.apiKey, !key.isEmpty {
            do {
                let backend = GeminiBackend(apiKey: key)
                let result = try await backend.run(mode: mode, userQuery: userQuery, context: context)
                lastBackendUsed = backend.name
                return result
            } catch {
                lastBackendUsed = "Gemini (error)"
                return .placeholder(mode: mode, missing: ["gemini_error: \(error.localizedDescription)"])
            }
        }

        lastBackendUsed = "None"
        return .placeholder(mode: mode, missing: ["apple_intelligence_unavailable", "gemini_api_key_not_configured_in_xcode"])
    }
}

// MARK: - Protocol reference builder
// Turns the app's already-computed protocol data (same formulas the UI
// screens use) into short reference strings the model may cite from, and
// packages the current checklist/patient state into a CopilotContextPayload.

@MainActor
enum ProtocolReferenceBuilder {
    static func buildPayload(from store: CopilotContextStore) -> CopilotContextPayload {
        var refs: [String] = []

        if store.weightKg > 0 {
            let d = DrugDoses(weightKg: store.weightKg)
            refs.append("drug.adrenaline_iv = \(d.fmt(d.epiIVLow))–\(d.fmt(d.epiIVHigh)) mL (0.1–0.3 mL/kg, 1:10,000 IV/UVC)")
            refs.append("drug.adrenaline_et = \(d.fmt(d.epiETLow))–\(d.fmt(d.epiETHigh)) mL (0.5–1.0 mL/kg ET)")
            refs.append("drug.fluid_bolus = \(d.fmt(d.fluidBolus, decimals: 1)) mL (10 mL/kg 0.9% saline)")
            refs.append("drug.dextrose10 = \(d.fmt(d.dextrose10, decimals: 1)) mL (2.5 mL/kg)")
            refs.append("drug.note = sodium bicarbonate is no longer recommended (SNRC 2026)")

            for drug in infusionDrugs {
                let amount = fmtNum(drug.amountToAdd(weightKg: store.weightKg))
                refs.append("infusion.\(drug.name.lowercased()) = add \(amount) \(drug.addedUnit) to 50 mL; \(drug.concentrationLabel); usual range \(drug.titrationRangeLabel)")
            }
            for drug in ecmoAppendixDrugs {
                if let range = drug.rangeText(weightKg: store.weightKg) {
                    refs.append("ecmo.\(drug.name) = \(range) (\(drug.dosingLabel), \(drug.route))")
                }
            }
        }

        if store.gaWeeks > 0 || store.weightKg > 0 {
            let row = ettRowForGA(store.gaWeeks, weight: store.weightKg)
            refs.append("equipment.ett = size \(row.ettSize) mm ID, depth \(row.depthRange), suction \(row.suctionFr)")
            if store.weightKg > 0 {
                refs.append("equipment.ett_depth_tochen = \(tochensDepth(store.weightKg))")
            }
        }

        let checklistPayloads = store.checklists.values.map {
            CopilotContextPayload.ChecklistPayload(name: $0.id, done: $0.doneCount, total: $0.totalCount, missingItems: $0.missing)
        }.sorted { $0.name < $1.name }

        var apgarDict: [String: Int]? = nil
        if let a = store.apgar {
            apgarDict = ["appearance": a.appearance, "pulse": a.pulse, "grimace": a.grimace, "activity": a.activity, "respiration": a.respiration]
        }

        return CopilotContextPayload(
            weightKg: store.weightKg,
            gaWeeks: store.gaWeeks,
            apgar: apgarDict,
            apgarTotal: store.apgar?.total,
            currentScreen: store.currentScreen,
            checklists: checklistPayloads,
            protocolReference: refs
        )
    }
}

// MARK: - Build-time Gemini API key (configured in Xcode, not per-user)
//
// Setup (one-time, in Xcode):
//   1. Create a file `Config.xcconfig` in your project (File > New > File >
//      Configuration Settings File), NOT added to source control, containing:
//         GEMINI_API_KEY = your_actual_key_here
//   2. In your target's Info.plist, add a key:
//         GEMINI_API_KEY = $(GEMINI_API_KEY)
//   3. In Project Settings > Info > Configurations, assign Config.xcconfig
//      to your Debug/Release configurations.
// The key then ships baked into the app bundle at build time — end users
// never see a field to type one in.
enum GeminiConfig {
    static var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !key.isEmpty,
              !key.hasPrefix("$(") else { // unresolved build variable = not configured
            return nil
        }
        return key
    }

    static var isConfigured: Bool { apiKey != nil }
}
