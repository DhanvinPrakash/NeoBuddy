//
//  ContentView.swift
//  kkhs2
//
//  Consolidated single-file build: patient inputs, resuscitation tab,
//  infusions, equipment checklist, ECMO activation (standard + eCPR),
//  cardiac arrhythmia algorithms, and the restructured Conditions tab
//  (Neonatal Emergencies + Checklists for High-risk Deliveries).
//
//  Depends on your existing (unchanged) files: Theme.swift,
//  SharedComponents.swift, DrugsSectionView.swift, APGARSectionView.swift,
//  ResuscitationAlgorithmView.swift, and CommonConditionsView (wherever
//  that lives in your project).
//


import SwiftUI
import Combine


// MARK: - ============================================================
// MARK: - InteractiveChecklist.swift
// MARK: - ============================================================

struct ChecklistItem: Identifiable, Hashable {
    let id: String          // stable id, e.g. "ecmo.doctor.consultant.1"
    let text: String
}

// MARK: - Persisted-in-memory checklist state
/// One of these drives an entire card of checkboxes. Kept as a class so
/// multiple nested views (progress ring, reset button, rows) can share it.
final class ChecklistState: ObservableObject {
    @Published var checked: Set<String> = []

    func isChecked(_ id: String) -> Bool { checked.contains(id) }

    func toggle(_ id: String) {
        if checked.contains(id) { checked.remove(id) } else { checked.insert(id) }
    }

    func reset(ids: [String]) {
        for id in ids { checked.remove(id) }
    }

    func progress(of ids: [String]) -> Double {
        guard !ids.isEmpty else { return 0 }
        let done = ids.filter { checked.contains($0) }.count
        return Double(done) / Double(ids.count)
    }
}

// MARK: - Single tappable checklist row
struct ChecklistRow: View {
    let item: ChecklistItem
    @ObservedObject var state: ChecklistState
    var accent: Color = AppTheme.accent

    var body: some View {
        let done = state.isChecked(item.id)
        Button {
            Haptics.checklistTap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                state.toggle(item.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: done ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(done ? accent : AppTheme.textSecondary.opacity(0.6))
                    .padding(.top, 1)
                Text(item.text)
                    .font(.subheadline)
                    .foregroundColor(done ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .strikethrough(done, color: AppTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - A titled card containing a group of checklist rows
// Styled to match the app's one canonical card (`.sectionCard()` /
// `.appCard()` — see Theme.swift and ConditionDetailView): a neutral
// surfaceElevated background with a hairline border, not a per-role
// tinted box. `color` is now used only as a small label accent (the way
// InfoRow/DoseCalcRow use color for a single value) so roles stay easy
// to tell apart without the screen turning into a box of crayons, and
// checkmarks always read as the same "done" green used everywhere else
// in the app (ConditionDetailView's manpower checklist, in particular).
struct RoleChecklistCard: View {
    let roleTitle: String
    let subtitle: String?
    let color: Color
    let items: [ChecklistItem]
    @ObservedObject var state: ChecklistState

    init(roleTitle: String, subtitle: String? = nil, color: Color, items: [ChecklistItem], state: ChecklistState) {
        self.roleTitle = roleTitle
        self.subtitle = subtitle
        self.color = color
        self.items = items
        self.state = state
    }

    var ids: [String] { items.map(\.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(roleTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(color)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2.bold())
                            .foregroundColor(AppTheme.textSecondary)
                            .textCase(.uppercase)
                    }
                }
                Spacer()
                ProgressBadge(progress: state.progress(of: ids), color: AppTheme.success)
            }

            ForEach(items) { item in
                ChecklistRow(item: item, state: state, accent: AppTheme.success)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous).stroke(AppTheme.accentMuted.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Small circular progress badge, e.g. "3/5"
struct ProgressBadge: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Reset-all button for a set of checklist ids
struct ChecklistResetButton: View {
    let allIDs: [String]
    @ObservedObject var state: ChecklistState

    var body: some View {
        Button {
            Haptics.mediumTap()
            withAnimation { state.reset(ids: allIDs) }
        } label: {
            Label("Reset Checklist", systemImage: "arrow.counterclockwise")
                .font(.caption.bold())
                .foregroundColor(AppTheme.danger)
        }
    }
}

// MARK: - Weight-based calculated dose row (label / formula / result)
struct DoseCalcRow: View {
    let label: String
    let formula: String
    let result: String
    var color: Color = AppTheme.accent

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                Text(formula)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Text(result)
                .font(.subheadline.bold())
                .foregroundColor(color)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(color.opacity(0.06))
        .cornerRadius(9)
    }
}

// MARK: - Generic weight entry field usable inside any section
struct WeightEntryField: View {
    let label: String
    @Binding var weight: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(AppTheme.textSecondary)
            TextField("e.g. 3.2", text: $weight)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(AppTheme.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.accentMuted.opacity(0.6), lineWidth: 1)
                )
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Number formatting helper
func fmtNum(_ v: Double, decimals: Int = 2) -> String {
    String(format: "%.\(decimals)f", v)
}

// MARK: - ============================================================
// MARK: - Weight-or-Gestational-Age shared input
// ============================================================
// Every screen that needs a patient weight is now required to capture
// EXACTLY one of "weight" or "gestational age" — never a blank ambiguous
// state, and never both. When only gestational age is known, weight is
// estimated (Fenton 2013 growth chart, 50th percentile) so every
// weight-based calculator in the app still has a usable number, clearly
// labelled as an estimate wherever it's shown.

enum PatientMeasurementMode: Int, CaseIterable, Hashable {
    case weight = 0
    case gestationalAge = 1

    var label: String {
        switch self {
        case .weight: return "Weight"
        case .gestationalAge: return "Gestational Age"
        }
    }
}

/// Fenton (2013) growth chart, 50th-percentile birth weight in kg by
/// completed gestational week. Weeks outside 22–42 clamp to the nearest
/// tabulated value.
private let fentonMedianWeightKg: [Int: Double] = [
    22: 0.46, 23: 0.54, 24: 0.63, 25: 0.72, 26: 0.82, 27: 0.93,
    28: 1.04, 29: 1.16, 30: 1.32, 31: 1.50, 32: 1.70, 33: 1.92,
    34: 2.15, 35: 2.38, 36: 2.62, 37: 2.85, 38: 3.05, 39: 3.21,
    40: 3.34, 41: 3.44, 42: 3.51
]

func estimatedWeightKg(forGAWeeks ga: Int) -> Double {
    guard ga > 0 else { return 0 }
    let clamped = min(max(ga, 22), 42)
    return fentonMedianWeightKg[clamped] ?? 0
}

/// Resolves whichever of the two fields is active into a usable weight.
func resolveWeightKg(mode: PatientMeasurementMode, weightText: String, gaText: String) -> Double {
    switch mode {
    case .weight:         return Double(weightText) ?? 0
    case .gestationalAge: return estimatedWeightKg(forGAWeeks: Int(gaText) ?? 0)
    }
}

/// One required choice + one field — replaces the old pattern of two
/// free-form fields that silently cleared each other. Styled identically
/// to every other text input in the app (same field chrome as
/// `WeightEntryField` / `inputField`) and to the Standard/eCPR-style mode
/// switches already used on this screen, so it reads as native to the
/// rest of the UI rather than a bespoke control.
struct WeightOrGAInput: View {
    let label: String
    @Binding var mode: PatientMeasurementMode
    @Binding var weightText: String
    @Binding var gaText: String
    @FocusState private var isFocused: Bool

    private var estimateNote: String? {
        guard mode == .gestationalAge, let ga = Int(gaText), ga > 0 else { return nil }
        return "≈ \(fmtNum(estimatedWeightKg(forGAWeeks: ga), decimals: 2)) kg estimated from gestational age (Fenton 50th percentile)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(AppTheme.textSecondary)

            Picker("", selection: $mode) {
                ForEach(PatientMeasurementMode.allCases, id: \.self) { m in
                    Text(m.label).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { new in
                // Only one of the two is ever "live" — clear the other so
                // stale text can never leak into a calculation.
                if new == .weight { gaText = "" } else { weightText = "" }
            }

            HStack(spacing: 8) {
                Group {
                    if mode == .weight {
                        TextField("e.g. 3.2", text: $weightText)
                            .keyboardType(.decimalPad)
                    } else {
                        TextField("e.g. 32", text: $gaText)
                            .keyboardType(.numberPad)
                    }
                }
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { isFocused = false }

                // Tick to confirm the entry and put the keypad away.
                if isFocused {
                    Button {
                        Haptics.checklistTap()
                        isFocused = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.accent)
                    }
                    .accessibilityLabel("Confirm entry")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .padding(10)
            .background(AppTheme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.accentMuted.opacity(0.6), lineWidth: 1))
            .foregroundColor(AppTheme.textPrimary)

            if let estimateNote {
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: "info.circle.fill").font(.caption2)
                    Text(estimateNote)
                        .font(.caption2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - InfusionsView.swift
// MARK: - ============================================================

struct InfusionDrug: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    /// multiplier applied to weight(kg) to get the amount to add to the 50 mL syringe
    let doseMultiplier: Double
    /// unit of the amount added ("mg" or "mcg")
    let addedUnit: String
    /// text describing what 1 mL/hr delivers, already weight-normalised
    let concentrationLabel: String
    /// the dose-per-kg represented by 1 mL/hr, used for the rate calculator (per min or per hr, matches concentrationUnit)
    let mLPerHrEquivalent: Double
    let concentrationUnit: String   // "mcg/kg/hr" or "mcg/kg/min"
    let titrationRangeLabel: String
    let titrationLow: Double
    let titrationHigh: Double
    let warning: String?
    let diluent: String

    /// mg or mcg to draw up for a given weight, diluted to 50 mL total with diluent
    func amountToAdd(weightKg: Double) -> Double { weightKg * doseMultiplier }
}

let infusionDrugs: [InfusionDrug] = [
    InfusionDrug(
        name: "Morphine",
        color: AppTheme.purple,
        doseMultiplier: 1,
        addedUnit: "mg",
        concentrationLabel: "1 mL/hr = 20 mcg/kg/hr",
        mLPerHrEquivalent: 20,
        concentrationUnit: "mcg/kg/hr",
        titrationRangeLabel: "2 – 20 mcg/kg/hr",
        titrationLow: 2, titrationHigh: 20,
        warning: nil,
        diluent: "D5% or NS"
    ),
    InfusionDrug(
        name: "Dopamine",
        color: AppTheme.accent,
        doseMultiplier: 60,
        addedUnit: "mg",
        concentrationLabel: "1 mL/hr = 20 mcg/kg/min",
        mLPerHrEquivalent: 20,
        concentrationUnit: "mcg/kg/min",
        titrationRangeLabel: "2 – 20 mcg/kg/min",
        titrationLow: 2, titrationHigh: 20,
        warning: "Central line infusion only",
        diluent: "D5% or NS"
    ),
    InfusionDrug(
        name: "Dobutamine",
        color: AppTheme.teal,
        doseMultiplier: 60,
        addedUnit: "mg",
        concentrationLabel: "1 mL/hr = 20 mcg/kg/min",
        mLPerHrEquivalent: 20,
        concentrationUnit: "mcg/kg/min",
        titrationRangeLabel: "2 – 20 mcg/kg/min",
        titrationLow: 2, titrationHigh: 20,
        warning: "Central line infusion only",
        diluent: "D5% or NS"
    ),
    InfusionDrug(
        name: "Adrenaline",
        color: AppTheme.danger,
        doseMultiplier: 0.3,
        addedUnit: "mg",
        concentrationLabel: "1 mL/hr = 0.1 mcg/kg/min",
        mLPerHrEquivalent: 0.1,
        concentrationUnit: "mcg/kg/min",
        titrationRangeLabel: "0.01 – 0.2 mcg/kg/min",
        titrationLow: 0.01, titrationHigh: 0.2,
        warning: "Central line infusion only",
        diluent: "D5% or NS"
    ),
    InfusionDrug(
        name: "PGE1 (Prostin) — for congenital heart disease",
        color: AppTheme.warning,
        doseMultiplier: 30,
        addedUnit: "mcg",
        concentrationLabel: "1 mL/hr = 0.01 mcg/kg/min",
        mLPerHrEquivalent: 0.01,
        concentrationUnit: "mcg/kg/min",
        titrationRangeLabel: "Titrate to clinical effect — confirm range with cardiology",
        titrationLow: 0, titrationHigh: 0,
        warning: nil,
        diluent: "D5% or NS"
    )
]

// MARK: - Infusions Section View (embed in a CollapsibleSection or its own tab)
struct InfusionsSectionView: View {
    @Binding var weight: String
    var weightKg: Double { Double(weight) ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Infusions", systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Text("All infusions diluted to a total volume of 50 mL")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            WeightEntryField(label: "Patient Weight (kg)", weight: $weight)

            if weightKg > 0 {
                ForEach(infusionDrugs) { drug in
                    InfusionDrugCard(drug: drug, weightKg: weightKg)
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.warning)
                        .font(.caption)
                    Text("Double-check all dilutions and rates with a second clinician before administration. Verify PGE1 titration range locally with cardiology.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(10)
                .background(AppTheme.warning.opacity(0.07))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.warning.opacity(0.2), lineWidth: 1))
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(AppTheme.accentLight)
                    Text("Enter patient weight to calculate infusion dilutions and rates.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .italic()
                }
            }
        }
    }
}

// MARK: - Individual drug card, with a rate calculator
private struct InfusionDrugCard: View {
    let drug: InfusionDrug
    let weightKg: Double
    @State private var desiredDose: String = ""

    var addedAmount: Double { drug.amountToAdd(weightKg: weightKg) }

    var calculatedRate: Double? {
        guard let dose = Double(desiredDose), dose > 0, drug.mLPerHrEquivalent > 0 else { return nil }
        return dose / drug.mLPerHrEquivalent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(drug.color).frame(width: 9, height: 9)
                Text(drug.name)
                    .font(.subheadline.bold())
                    .foregroundColor(drug.color)
            }

            DoseCalcRow(
                label: "Add to syringe",
                formula: "wt (\(fmtNum(weightKg))) × \(fmtNum(drug.doseMultiplier, decimals: drug.doseMultiplier < 1 ? 2 : (drug.doseMultiplier == drug.doseMultiplier.rounded() ? 0 : 2)))",
                result: "\(fmtNum(addedAmount, decimals: 2)) \(drug.addedUnit)",
                color: drug.color
            )
            DoseCalcRow(
                label: "Diluent",
                formula: "made up to total volume",
                result: "50 mL \(drug.diluent)",
                color: drug.color
            )
            DoseCalcRow(
                label: "Final concentration",
                formula: "at this weight, per mL/hr",
                result: drug.concentrationLabel,
                color: drug.color
            )
            DoseCalcRow(
                label: "Usual titration range",
                formula: "",
                result: drug.titrationRangeLabel,
                color: drug.color
            )

            // Rate calculator
            VStack(alignment: .leading, spacing: 6) {
                Text("Rate calculator")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.textSecondary)
                HStack(spacing: 8) {
                    TextField("Desired dose (\(drug.concentrationUnit))", text: $desiredDose)
                        .keyboardType(.decimalPad)
                        .padding(8)
                        .background(AppTheme.surface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(drug.color.opacity(0.3), lineWidth: 1))
                        .font(.subheadline)
                    Text("→")
                        .foregroundColor(AppTheme.textSecondary)
                    Text(calculatedRate != nil ? "\(fmtNum(calculatedRate!, decimals: 2)) mL/hr" : "— mL/hr")
                        .font(.subheadline.bold())
                        .foregroundColor(drug.color)
                        .frame(minWidth: 80, alignment: .leading)
                }
            }
            .padding(.top, 2)

            if let warning = drug.warning {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(AppTheme.danger)
                    Text(warning)
                        .font(.caption2.bold())
                        .foregroundColor(AppTheme.danger)
                }
            }
        }
        .padding(12)
        .background(drug.color.opacity(0.04))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(drug.color.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - ============================================================
// MARK: - EquipmentSectionView.swift
// MARK: - ============================================================

struct ETTTableRow {
    let gestAgeLabel: String
    let weightLabel: String
    let ettSize: String
    let depthRange: String
    let suctionFr: String
}

// SNRC 2026 Table 2 — ETT size and depth of tube placement for oral intubation
let ettTable: [ETTTableRow] = [
    ETTTableRow(gestAgeLabel: "< 25 wk",    weightLabel: "< 600 g",         ettSize: "2.0 – 2.5", depthRange: "5.5 – 6.0 cm", suctionFr: "5 – 6 Fr"),
    ETTTableRow(gestAgeLabel: "25 – 28 wk", weightLabel: "600 – 1,000 g",   ettSize: "2.5", depthRange: "6.0 – 6.5 cm", suctionFr: "6 Fr"),
    ETTTableRow(gestAgeLabel: "29 – 34 wk", weightLabel: "1,000 – 2,000 g", ettSize: "3.0", depthRange: "7.0 – 8.0 cm", suctionFr: "6 Fr"),
    ETTTableRow(gestAgeLabel: "35 – 38 wk", weightLabel: "2,000 – 3,000 g", ettSize: "3.5", depthRange: "8.0 – 9.0 cm", suctionFr: "8 Fr"),
    ETTTableRow(gestAgeLabel: "> 38 wk",    weightLabel: "3,000 – 4,000 g", ettSize: "3.5", depthRange: "9.0 – 10.0 cm", suctionFr: "8 Fr")
]

func ettRowForGA(_ ga: Int, weight: Double) -> ETTTableRow {
    if ga > 0 {
        if ga < 25  { return ettTable[0] }
        if ga <= 28 { return ettTable[1] }
        if ga <= 34 { return ettTable[2] }
        if ga <= 38 { return ettTable[3] }
        return ettTable[4]
    }
    // Fallback by weight (kg)
    if weight < 0.6 { return ettTable[0] }
    if weight < 1   { return ettTable[1] }
    if weight < 2   { return ettTable[2] }
    if weight < 3   { return ettTable[3] }
    return ettTable[4]
}

func tochensDepth(_ weightKg: Double) -> String {
    let depth = weightKg + 6
    return String(format: "%.0f cm (Tochen's formula: wt + 6)", depth)
}

// Now expressed as ChecklistItem so it can be tapped/tracked, same pattern
// used by the ECMO and Arrhythmia checklists.
let standardEquipmentItems: [ChecklistItem] = [
    ChecklistItem(id: "equip.1", text: "Overhead radiant warmer (room 23–25°C; ≥ 25°C if < 33 wk)"),
    ChecklistItem(id: "equip.2", text: "Cap for thermoregulation (especially < 33 wk)"),
    ChecklistItem(id: "equip.3", text: "Polyethylene wrap (if < 33 wk, without drying)"),
    ChecklistItem(id: "equip.4", text: "Warm towels"),
    ChecklistItem(id: "equip.5", text: "Stethoscope"),
    ChecklistItem(id: "equip.6", text: "Pulse oximeter — right hand (preductal)"),
    ChecklistItem(id: "equip.7", text: "3-lead ECG electrodes — preferred for continuous HR in ongoing resus"),
    ChecklistItem(id: "equip.8", text: "T-piece resuscitator (preferred over self-inflating bag)"),
    ChecklistItem(id: "equip.9", text: "Self-inflating bag + appropriate face mask (backup)"),
    ChecklistItem(id: "equip.10", text: "Video laryngoscope (direct laryngoscope as backup) + blades (0, 00)"),
    ChecklistItem(id: "equip.11", text: "Suction device (80–100 mmHg)"),
    ChecklistItem(id: "equip.12", text: "Umbilical venous catheter kit (intraosseous access as alternative)"),
    ChecklistItem(id: "equip.13", text: "Capnography / colorimetric CO₂ detector"),
    ChecklistItem(id: "equip.14", text: "Supraglottic airway device (LMA) — ≥ 34 wk or > 1500 g"),
    ChecklistItem(id: "equip.15", text: "IV access supplies")
]

// MARK: - Equipment View
struct EquipmentSectionView: View {
    let weightKg: Double
    let gaWeeks: Int
    @EnvironmentObject private var copilotContextStore: CopilotContextStore
    @StateObject private var checklistState = ChecklistState()

    var row: ETTTableRow {
        ettRowForGA(gaWeeks, weight: weightKg)
    }

    var hasInput: Bool { weightKg > 0 || gaWeeks > 0 }
    var basisLabel: String {
        if gaWeeks > 0 { return "\(gaWeeks) wk gestation" }
        return "\(String(format: "%.2f", weightKg)) kg (weight-based estimate)"
    }

    private func publishToCopilot() {
        let items = standardEquipmentItems.map { (id: $0.id, text: $0.text, done: checklistState.isChecked($0.id)) }
        copilotContextStore.publishChecklist("equipment", items: items)
    }

    var body: some View {
        Group {
        if hasInput {
            VStack(alignment: .leading, spacing: 12) {
                // Source label
                HStack(spacing: 6) {
                    Image(systemName: "table")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("SNRC 2026 Table 2 — \(basisLabel)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                // ETT Specs
                VStack(alignment: .leading, spacing: 6) {
                    Text("Endotracheal Tube")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.bottom, 2)

                    EquipRow(label: "ETT Internal Diameter", value: "\(row.ettSize) mm")
                    EquipRow(label: "Depth — table range", value: row.depthRange)
                    if weightKg > 0 {
                        EquipRow(label: "Depth — Tochen's formula", value: tochensDepth(weightKg))
                    }
                    EquipRow(label: "Suction Catheter Size", value: row.suctionFr)
                }

                Divider().background(AppTheme.accentMuted.opacity(0.4)).padding(.vertical, 2)

                // Standard equipment checklist — now interactive
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Standard Equipment Checklist")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        ProgressBadge(progress: checklistState.progress(of: standardEquipmentItems.map(\.id)), color: AppTheme.accent)
                    }
                    .padding(.bottom, 2)

                    ForEach(standardEquipmentItems) { item in
                        ChecklistRow(item: item, state: checklistState, accent: AppTheme.accent)
                    }

                    HStack {
                        Spacer()
                        ChecklistResetButton(allIDs: standardEquipmentItems.map(\.id), state: checklistState)
                    }
                }
            }
        } else {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(AppTheme.accentLight)
                Text("Enter weight and/or gestational age to see equipment recommendations.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .italic()
            }
        }
        }
        .onAppear { publishToCopilot() }
        .onChange(of: checklistState.checked) { _ in publishToCopilot() }
        .onDisappear { copilotContextStore.removeChecklist("equipment") }
    }
}

// MARK: - ============================================================
// MARK: - ECMOActivationView.swift
// MARK: - ============================================================

struct ECMOAppendixDrug {
    let name: String
    let dosingLabel: String
    let route: String
    let special: String
    /// nil if the dose isn't a simple per-kg multiple (e.g. fixed dose)
    let perKgLow: Double?
    let perKgHigh: Double?
    let unit: String
    let fixedDose: Double?      // used when the dose is not weight based (e.g. CaCl 1.5 mmol)
    let fixedUnit: String?

    func rangeText(weightKg: Double) -> String? {
        guard weightKg > 0, let low = perKgLow else { return nil }
        let high = perKgHigh ?? low
        if low == high {
            return "\(fmtNum(low * weightKg, decimals: 2)) \(unit)"
        }
        return "\(fmtNum(low * weightKg, decimals: 2)) – \(fmtNum(high * weightKg, decimals: 2)) \(unit)"
    }
}

let ecmoAppendixDrugs: [ECMOAppendixDrug] = [
    ECMOAppendixDrug(name: "Heparin Sodium 1000 unit/mL", dosingLabel: "25 – 50 Units/kg", route: "IV Bolus", special: "Check with CICU/CTS dose required", perKgLow: 25, perKgHigh: 50, unit: "Units", fixedDose: nil, fixedUnit: nil),
    ECMOAppendixDrug(name: "Adrenaline 1:10,000", dosingLabel: "0.1 mL/kg", route: "IV Bolus", special: "Prepare at least 3 doses for resus if needed", perKgLow: 0.1, perKgHigh: nil, unit: "mL", fixedDose: nil, fixedUnit: nil),
    ECMOAppendixDrug(name: "Albumin 5% Solution", dosingLabel: "10 mL/kg", route: "IV Bolus", special: "For volume resuscitation if needed", perKgLow: 10, perKgHigh: nil, unit: "mL", fixedDose: nil, fixedUnit: nil),
    ECMOAppendixDrug(name: "Sodium Chloride 0.9%", dosingLabel: "10 mL/kg", route: "IV Bolus", special: "For volume resuscitation if needed", perKgLow: 10, perKgHigh: nil, unit: "mL", fixedDose: nil, fixedUnit: nil),
    ECMOAppendixDrug(name: "Calcium Chloride 10% (6.8 mmol/10 mL)", dosingLabel: "1.5 mmol", route: "IV Bolus", special: "Administer once ECMO flows established", perKgLow: nil, perKgHigh: nil, unit: "", fixedDose: 1.5, fixedUnit: "mmol")
]

// MARK: - Root View with Standard / eCPR toggle
// Restyled to match the rest of the app: the title/picker/weight block now
// sits in the same raised `.appCard()` used for "Patient Details" on the
// Resuscitation tab, and the protocol citation uses the same icon + caption
// row as the resuscitation algorithm's source line, instead of a bare
// caption. Sub-cards below use the shared AppTheme.Spacing/Radius scale
// instead of hard-coded numbers.
struct ECMOActivationView: View {
    @State private var activationMode: Int = 0  // 0 = standard activation, 1 = eCPR activation
    @State private var measurementMode: PatientMeasurementMode = .weight
    @State private var weightText: String = ""
    @State private var gaText: String = ""

    private var weightKg: Double {
        resolveWeightKg(mode: measurementMode, weightText: weightText, gaText: gaText)
    }
    /// Downstream sub-views take a plain weight string (same contract as
    /// every other screen's dose calculators) — this is that string,
    /// whether it came from direct entry or from the GA estimate.
    private var resolvedWeight: String {
        weightKg > 0 ? fmtNum(weightKg, decimals: 2) : ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {

            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Label("Neonatal ECMO Activation", systemImage: "waveform.path.ecg.rectangle")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption2)
                        Text("Protocol 67510-0015 · 1 Jul 2022")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }

                Picker("Mode", selection: $activationMode) {
                    Text("Standard Activation").tag(0)
                    Text("eCPR Activation").tag(1)
                }
                .pickerStyle(.segmented)

                WeightOrGAInput(
                    label: "Weight or Gestational Age — for drug dosing",
                    mode: $measurementMode,
                    weightText: $weightText,
                    gaText: $gaText
                )
            }
            .appCard()

            if activationMode == 0 {
                StandardECMOView(weight: resolvedWeight)
            } else {
                ECPRActivationView(weight: resolvedWeight)
            }

            ECMODrugAppendixCard(weight: resolvedWeight)
            ECMORoomSetupCard()
        }
    }
}

// MARK: - Standard Activation
private struct StandardECMOView: View {
    let weight: String
    @StateObject private var state = ChecklistState()

    private let indications = [
        "Inadequate tissue oxygen delivery despite maximal therapy (rising lactate, worsening metabolic acidosis, signs of end organ dysfunction)",
        "Severe hypoxic respiratory failure with acute decompensation (PaO₂ < 40 mmHg)",
        "Oxygenation index persistently elevated with no improvement (> 40 for 4 h or > 20 for 24 h despite maximal medical therapy)",
        "Severe pulmonary hypertension with RV and/or LV dysfunction"
    ]
    private let contraindications = [
        "Lethal chromosomal disorder (e.g. Trisomy 13, 18)",
        "Severe brain damage",
        "Uncontrollable bleeding",
        "Significant intracranial or intraventricular haemorrhage",
        "Vessel size too small for cannulation"
    ]
    private let relativeContraindications = [
        "Irreversible organ damage",
        "< 2 kg",
        "< 34 weeks gestation"
    ]

    // Pre-activation
    private let preNeonatalConsultant = [
        ChecklistItem(id: "std.pre.consultant.1", text: "Contact CICU consultant on-call/service to review case"),
        ChecklistItem(id: "std.pre.consultant.2", text: "Post discussion: CICU team will contact Cardiology/CTS if needed"),
        ChecklistItem(id: "std.pre.consultant.3", text: "Ensure adequate central venous access (if possible)"),
        ChecklistItem(id: "std.pre.consultant.4", text: "Pre-empt parents of potential for ECMO"),
        ChecklistItem(id: "std.pre.consultant.5", text: "Send investigations: FBC, renal panel, PT/PTT, GXM, cranial ultrasound; ensure IEM screen sent")
    ]
    private let preNursing = [
        ChecklistItem(id: "std.pre.nursing.1", text: "Decant patients from room if possible"),
        ChecklistItem(id: "std.pre.nursing.2", text: "Inform ECMO nursing team of potential ECMO candidate")
    ]

    // Post-decision doctor roles
    private let consultantPre = [
        ChecklistItem(id: "std.consultant.pre.1", text: "Contact CICU consultant on call (CICU will contact CTS on call)"),
        ChecklistItem(id: "std.consultant.pre.2", text: "Parents to come in to sign consent"),
        ChecklistItem(id: "std.consultant.pre.3", text: "Prepare to position, in discussion with CICU/CTS")
    ]
    private let consultantDuring = [ChecklistItem(id: "std.consultant.during.1", text: "Lead resus as needed until ECMO cannulation starts")]
    private let consultantPost = [
        ChecklistItem(id: "std.consultant.post.1", text: "Ensure handover complete"),
        ChecklistItem(id: "std.consultant.post.2", text: "Debrief team post transfer"),
        ChecklistItem(id: "std.consultant.post.3", text: "Ensure primary consultant for patient is identified")
    ]

    private let reg1Pre = [
        ChecklistItem(id: "std.reg1.pre.1", text: "Contact Anaesthesia on call"),
        ChecklistItem(id: "std.reg1.pre.2", text: "Contact Cardiology on call")
    ]
    private let reg1Post = [ChecklistItem(id: "std.reg1.post.1", text: "Ensure complete documentation of events and summary done")]

    private let moItems = [ChecklistItem(id: "std.mo.1", text: "Run to blood bank for 1 unit leucodepleted PCT for priming of circuit")]

    private let reg2Items = [
        ChecklistItem(id: "std.reg2.1", text: "Prepare drugs for ECMO activation (see Drug Appendix below)"),
        ChecklistItem(id: "std.reg2.2", text: "Nurse in charge of drugs to ensure fentanyl and rocuronium are also taken for anaesthetist use")
    ]

    private let cicuPre = [
        ChecklistItem(id: "std.cicu.pre.1", text: "Contact CTS consultant and inform ECMO specialist"),
        ChecklistItem(id: "std.cicu.pre.2", text: "ECMO consent (CTS will take operative consent)")
    ]
    private let cicuDuring = [
        ChecklistItem(id: "std.cicu.during.1", text: "Overall team lead for ECMO cannulation"),
        ChecklistItem(id: "std.cicu.during.2", text: "eCPR timing if necessary")
    ]
    private let cicuPost = [
        ChecklistItem(id: "std.cicu.post.1", text: "Ensure team is ready for transport to CICU"),
        ChecklistItem(id: "std.cicu.post.2", text: "Complete CICU ECMO transport checklist")
    ]

    private let anaesthesiaPre = [ChecklistItem(id: "std.anaes.pre.1", text: "Prepare fentanyl and rocuronium")]
    private let anaesthesiaDuring = [
        ChecklistItem(id: "std.anaes.during.1", text: "Administration of all drugs"),
        ChecklistItem(id: "std.anaes.during.2", text: "Drawing of blood gases")
    ]

    private let ecmoNurse = [
        ChecklistItem(id: "std.nurse.ecmo.1", text: "Contact ECMO team (nurses/perfusionists)"),
        ChecklistItem(id: "std.nurse.ecmo.2", text: "Prepare ECMO circuit")
    ]
    private let bedsideNurse = [
        ChecklistItem(id: "std.nurse.bedside.1", text: "Position patient for ECMO"),
        ChecklistItem(id: "std.nurse.bedside.2", text: "Extend lines for procedure (venous and arterial)"),
        ChecklistItem(id: "std.nurse.bedside.3", text: "Ensure one dedicated line for medication"),
        ChecklistItem(id: "std.nurse.bedside.4", text: "Documentation")
    ]
    private let floaterNurse = [
        ChecklistItem(id: "std.nurse.floater.1", text: "Prepare drugs for ECMO activation as per Drug Appendix"),
        ChecklistItem(id: "std.nurse.floater.2", text: "Ensure fentanyl and rocuronium are also taken for anaesthetist use")
    ]
    private let chargeNurse = [
        ChecklistItem(id: "std.nurse.charge.1", text: "Ensure crowd control"),
        ChecklistItem(id: "std.nurse.charge.2", text: "Ensure enough space in room for procedure (shift other patients if needed)"),
        ChecklistItem(id: "std.nurse.charge.3", text: "Call security to ensure door between NICU and CICU is open when ready for transfer")
    ]

    var allIDs: [String] {
        [preNeonatalConsultant, preNursing, consultantPre, consultantDuring, consultantPost,
         reg1Pre, reg1Post, moItems, reg2Items, cicuPre, cicuDuring, cicuPost,
         anaesthesiaPre, anaesthesiaDuring, ecmoNurse, bedsideNurse, floaterNurse, chargeNurse]
            .flatMap { $0.map(\.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            // Candidacy reference
            ECMOCandidacyCard(indications: indications, contraindications: contraindications, relative: relativeContraindications)

            SectionHeader(title: "If YES — Before Activation", systemImage: "person.crop.circle.badge.exclamationmark", color: AppTheme.teal)
            RoleChecklistCard(roleTitle: "Neonatal Consultant to Contact", color: AppTheme.teal, items: preNeonatalConsultant, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Nursing Team", color: AppTheme.teal, items: preNursing, state: state)

            Divider().background(AppTheme.accentMuted.opacity(0.4)).padding(.vertical, AppTheme.Spacing.xs / 2)

            SectionHeader(title: "Once ECMO Activation Decided — Doctor Roles", systemImage: "stethoscope", color: AppTheme.accent)
            RoleChecklistCard(roleTitle: "Neonatal Consultant", subtitle: "Prior to cannulation", color: AppTheme.accent, items: consultantPre, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Consultant", subtitle: "During cannulation", color: AppTheme.accent, items: consultantDuring, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Consultant", subtitle: "Post cannulation", color: AppTheme.accent, items: consultantPost, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Reg/AC (1)", subtitle: "Prior to cannulation", color: AppTheme.purple, items: reg1Pre, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Reg/AC (1)", subtitle: "Post cannulation", color: AppTheme.purple, items: reg1Post, state: state)
            RoleChecklistCard(roleTitle: "Neonatal MO", subtitle: "Prior to cannulation", color: AppTheme.warning, items: moItems, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Reg/AC (2) + Code Nurse/Floater", subtitle: "Prior to cannulation", color: AppTheme.warning, items: reg2Items, state: state)
            RoleChecklistCard(roleTitle: "CICU Consultant", subtitle: "Prior to cannulation", color: AppTheme.danger, items: cicuPre, state: state)
            RoleChecklistCard(roleTitle: "CICU Consultant", subtitle: "During cannulation", color: AppTheme.danger, items: cicuDuring, state: state)
            RoleChecklistCard(roleTitle: "CICU Consultant", subtitle: "Post cannulation", color: AppTheme.danger, items: cicuPost, state: state)
            RoleChecklistCard(roleTitle: "Anaesthesia", subtitle: "Prior to cannulation", color: AppTheme.success, items: anaesthesiaPre, state: state)
            RoleChecklistCard(roleTitle: "Anaesthesia", subtitle: "During cannulation", color: AppTheme.success, items: anaesthesiaDuring, state: state)

            Divider().background(AppTheme.accentMuted.opacity(0.4)).padding(.vertical, AppTheme.Spacing.xs / 2)

            SectionHeader(title: "Once ECMO Activation Decided — Nurse Roles", systemImage: "cross.case.fill", color: AppTheme.teal)
            RoleChecklistCard(roleTitle: "ECMO Nurse + Code Nurse", subtitle: "Prior to cannulation", color: AppTheme.teal, items: ecmoNurse, state: state)
            RoleChecklistCard(roleTitle: "Bedside Nurse", color: AppTheme.textSecondary, items: bedsideNurse, state: state)
            RoleChecklistCard(roleTitle: "Code Nurse/Floater", color: AppTheme.accent, items: floaterNurse, state: state)
            RoleChecklistCard(roleTitle: "Shift Nurse in Charge", color: AppTheme.danger, items: chargeNurse, state: state)

            HStack {
                Spacer()
                ChecklistResetButton(allIDs: allIDs, state: state)
            }
        }
    }
}

// MARK: - eCPR Activation
private struct ECPRActivationView: View {
    let weight: String
    @StateObject private var state = ChecklistState()

    private let consultantPre = [
        ChecklistItem(id: "ecpr.consultant.pre.1", text: "Contact CICU consultant on call (CICU will contact CTS on call)"),
        ChecklistItem(id: "ecpr.consultant.pre.2", text: "Parents to come in to sign consent immediately"),
        ChecklistItem(id: "ecpr.consultant.pre.3", text: "Prepare to position patient, in discussion with CICU/CTS")
    ]
    private let consultantDuring = [ChecklistItem(id: "ecpr.consultant.during.1", text: "Lead resus as needed until ECMO cannulation starts")]
    private let consultantPost = [
        ChecklistItem(id: "ecpr.consultant.post.1", text: "Ensure handover complete"),
        ChecklistItem(id: "ecpr.consultant.post.2", text: "Debrief team post transfer"),
        ChecklistItem(id: "ecpr.consultant.post.3", text: "Ensure primary consultant for patient is identified")
    ]

    private let reg1Pre = [ChecklistItem(id: "ecpr.reg1.pre.1", text: "Contact Cardiology on call")]
    private let reg1During = [ChecklistItem(id: "ecpr.reg1.during.1", text: "Gown up for sterile CPR")]
    private let reg1Post = [ChecklistItem(id: "ecpr.reg1.post.1", text: "Ensure complete documentation of events and summary done")]

    private let moItems = [ChecklistItem(id: "ecpr.mo.1", text: "Run to blood bank for 1 unit leucodepleted PCT for priming of circuit")]

    private let reg2Items = [
        ChecklistItem(id: "ecpr.reg2.1", text: "Prepare drugs for ECMO activation (see Drug Appendix below)"),
        ChecklistItem(id: "ecpr.reg2.2", text: "Nurse in charge of drugs to ensure fentanyl and rocuronium are also taken for anaesthetist use")
    ]

    private let cicuPre = [
        ChecklistItem(id: "ecpr.cicu.pre.1", text: "Contact CTS consultant and inform ECMO specialist"),
        ChecklistItem(id: "ecpr.cicu.pre.2", text: "ECMO consent (CTS will take operative consent)")
    ]
    private let cicuDuring = [
        ChecklistItem(id: "ecpr.cicu.during.1", text: "Overall team lead for ECMO cannulation"),
        ChecklistItem(id: "ecpr.cicu.during.2", text: "eCPR timing if necessary")
    ]
    private let cicuPost = [
        ChecklistItem(id: "ecpr.cicu.post.1", text: "Ensure team is ready for transport to CICU"),
        ChecklistItem(id: "ecpr.cicu.post.2", text: "Complete CICU ECMO transport checklist")
    ]

    private let anaesthesiaPre = [ChecklistItem(id: "ecpr.anaes.pre.1", text: "Prepare fentanyl and rocuronium")]
    private let anaesthesiaDuring = [
        ChecklistItem(id: "ecpr.anaes.during.1", text: "Administration of all drugs"),
        ChecklistItem(id: "ecpr.anaes.during.2", text: "Drawing of blood gases")
    ]

    private let ecmoNurse = [
        ChecklistItem(id: "ecpr.nurse.ecmo.1", text: "Contact ECMO team (nurses/perfusionists)"),
        ChecklistItem(id: "ecpr.nurse.ecmo.2", text: "Prepare ECMO circuit")
    ]
    private let bedsideNurse = [
        ChecklistItem(id: "ecpr.nurse.bedside.1", text: "Position patient for ECMO"),
        ChecklistItem(id: "ecpr.nurse.bedside.2", text: "Extend lines for procedure (venous and arterial)"),
        ChecklistItem(id: "ecpr.nurse.bedside.3", text: "Ensure dedicated line for medication administration"),
        ChecklistItem(id: "ecpr.nurse.bedside.4", text: "Documentation"),
        ChecklistItem(id: "ecpr.nurse.bedside.5", text: "Time and call out every 3 min for adrenaline administration")
    ]
    private let codeFloaterNurse = [
        ChecklistItem(id: "ecpr.nurse.code.1", text: "Prepare drugs for ECMO activation as per Drug Appendix"),
        ChecklistItem(id: "ecpr.nurse.code.2", text: "Ensure fentanyl and rocuronium are also taken for anaesthetist use")
    ]
    private let chargeNurse = [
        ChecklistItem(id: "ecpr.nurse.charge.1", text: "Ensure crowd control"),
        ChecklistItem(id: "ecpr.nurse.charge.2", text: "Ensure enough space in room for procedure (shift other patients if needed)"),
        ChecklistItem(id: "ecpr.nurse.charge.3", text: "Call security to ensure door between NICU and CICU is open when ready for transfer")
    ]

    var allIDs: [String] {
        [consultantPre, consultantDuring, consultantPost, reg1Pre, reg1During, reg1Post,
         moItems, reg2Items, cicuPre, cicuDuring, cicuPost, anaesthesiaPre, anaesthesiaDuring,
         ecmoNurse, bedsideNurse, codeFloaterNurse, chargeNurse].flatMap { $0.map(\.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Label("Trigger", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.danger)
                    Spacer()
                    PillBadge(text: "eCPR", color: AppTheme.danger)
                }
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    triggerBullet("In-hospital collapse, no ROSC after 10 min")
                    triggerBullet("AND suitable for ECMO — potentially reversible cause (e.g. cardiac)")
                    triggerBullet("1. Inform NICU consultant on call; if agreeable, activate ECMO code")
                    triggerBullet("2. Continue resuscitation")
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.danger.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous).stroke(AppTheme.danger.opacity(0.2), lineWidth: 1))

            SectionHeader(title: "Doctor Roles", systemImage: "stethoscope", color: AppTheme.accent)
            RoleChecklistCard(roleTitle: "Neonatal Consultant", subtitle: "Prior to cannulation", color: AppTheme.accent, items: consultantPre, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Consultant", subtitle: "During cannulation", color: AppTheme.accent, items: consultantDuring, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Consultant", subtitle: "Post cannulation", color: AppTheme.accent, items: consultantPost, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Reg/AC (1)", subtitle: "Prior to cannulation", color: AppTheme.purple, items: reg1Pre, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Reg/AC (1)", subtitle: "During cannulation", color: AppTheme.purple, items: reg1During, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Reg/AC (1)", subtitle: "Post cannulation", color: AppTheme.purple, items: reg1Post, state: state)
            RoleChecklistCard(roleTitle: "Neonatal MO", subtitle: "Prior to cannulation", color: AppTheme.warning, items: moItems, state: state)
            RoleChecklistCard(roleTitle: "Neonatal Reg/AC (2) + Code Nurse/Floater", subtitle: "Prior to cannulation", color: AppTheme.warning, items: reg2Items, state: state)
            RoleChecklistCard(roleTitle: "CICU Consultant", subtitle: "Prior to cannulation", color: AppTheme.danger, items: cicuPre, state: state)
            RoleChecklistCard(roleTitle: "CICU Consultant", subtitle: "During cannulation", color: AppTheme.danger, items: cicuDuring, state: state)
            RoleChecklistCard(roleTitle: "CICU Consultant", subtitle: "Post cannulation", color: AppTheme.danger, items: cicuPost, state: state)
            RoleChecklistCard(roleTitle: "Anaesthesia", subtitle: "Prior to cannulation", color: AppTheme.success, items: anaesthesiaPre, state: state)
            RoleChecklistCard(roleTitle: "Anaesthesia", subtitle: "During cannulation", color: AppTheme.success, items: anaesthesiaDuring, state: state)

            Divider().background(AppTheme.accentMuted.opacity(0.4)).padding(.vertical, AppTheme.Spacing.xs / 2)

            SectionHeader(title: "Nurse Roles", systemImage: "cross.case.fill", color: AppTheme.teal)
            RoleChecklistCard(roleTitle: "ECMO Nurse + Code Nurse", subtitle: "Prior to cannulation", color: AppTheme.teal, items: ecmoNurse, state: state)
            RoleChecklistCard(roleTitle: "Bedside Nurse", color: AppTheme.textSecondary, items: bedsideNurse, state: state)
            RoleChecklistCard(roleTitle: "Code Nurse/Floater", color: AppTheme.accent, items: codeFloaterNurse, state: state)
            RoleChecklistCard(roleTitle: "Shift Nurse in Charge", color: AppTheme.danger, items: chargeNurse, state: state)

            HStack {
                Spacer()
                ChecklistResetButton(allIDs: allIDs, state: state)
            }
        }
    }

    private func triggerBullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs + 2) {
            Text("•").foregroundColor(AppTheme.danger)
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Candidacy Reference Card
// Previously the only sub-card on this screen without a `SectionHeader`
// (every other ECMO/eCPR card and the sibling Arrhythmia screen use one) —
// brought in line here.
private struct ECMOCandidacyCard: View {
    let indications: [String]
    let contraindications: [String]
    let relative: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: "ECMO Candidacy", systemImage: "checklist", color: .indigo)
            Text("Is the patient a candidate for ECMO in the event of deterioration?")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)

            bulletGroup(title: "Indications (≥ 1 of, with severe respiratory/cardiac failure, high mortality risk, potentially reversible)", items: indications, color: AppTheme.success)
            bulletGroup(title: "Contraindications", items: contraindications, color: AppTheme.danger)
            bulletGroup(title: "Relative Contraindications", items: relative, color: AppTheme.warning)
        }
        .sectionCard()
    }

    @ViewBuilder
    private func bulletGroup(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(color)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: AppTheme.Spacing.xs + 2) {
                    Text("•").foregroundColor(color)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
    }
}

// MARK: - Drug Appendix Card (Appendix 1)
// Each drug row now reads as an InfoRow-style line (label left, computed
// value right, in the drug's semantic color) inside the one canonical
// card, instead of its own individually tinted sub-box.
private struct ECMODrugAppendixCard: View {
    let weight: String
    var weightKg: Double { Double(weight) ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: "Appendix 1 — Drugs to Prepare During Cannulation", systemImage: "pills.fill", color: AppTheme.purple)

            ForEach(ecmoAppendixDrugs, id: \.name) { drug in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(drug.name)
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    HStack(alignment: .top) {
                        Text("\(drug.dosingLabel) · \(drug.route)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if weightKg > 0, let calc = drug.rangeText(weightKg: weightKg) {
                            Text(calc)
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.purple)
                        } else if let fixed = drug.fixedDose, let unit = drug.fixedUnit {
                            Text("\(fmtNum(fixed, decimals: 1)) \(unit)")
                                .font(.subheadline.bold())
                                .foregroundColor(AppTheme.purple)
                        }
                    }
                    if !drug.special.isEmpty {
                        Text(drug.special)
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)

                if drug.name != ecmoAppendixDrugs.last?.name {
                    Divider().background(AppTheme.accentMuted.opacity(0.3))
                }
            }

            Text("Anaesthesia: prepare rocuronium + fentanyl; confirm with team if further rocuronium infusion is needed. Order via CICU.ECMO.Initiation.KKH and CICU.ECMO.Circuit Priming.KKH.")
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, AppTheme.Spacing.xs / 2)
        }
        .sectionCard()
    }
}

// MARK: - Room Setup Reference
private struct ECMORoomSetupCard: View {
    private let roles: [(String, String)] = [
        ("S1 / S2", "Surgeon 1 / Surgeon 2"),
        ("SN", "Scrub Nurse"),
        ("P", "Perfusionist"),
        ("EN", "ECMO Nurse"),
        ("AN", "Anaesthetist")
    ]

    private let layoutPoints: [String] = [
        "Cot bed centred · O₂ blender overhead",
        "One side — ventilator, iNO machine, anaesthetist",
        "Other side — surgeons, scrub nurse, instrument tray",
        "Nearest door — perfusionist, ECMO machine, ECMO nurse",
        "Far side — infusion pumps, head light, diathermy"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: "NICU Isolation Bed Room Setup", systemImage: "square.grid.3x3.fill", color: AppTheme.teal)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                ForEach(layoutPoints, id: \.self) { point in
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs + 2) {
                        Text("•").foregroundColor(AppTheme.teal)
                        Text(point)
                            .font(.caption)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            FlowRoles(roles: roles)
        }
        .sectionCard()
    }
}

private struct FlowRoles: View {
    let roles: [(String, String)]
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            ForEach(roles, id: \.0) { pair in
                HStack {
                    Text(pair.0).font(.caption.bold()).foregroundColor(AppTheme.teal).frame(width: 50, alignment: .leading)
                    Text(pair.1).font(.caption).foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - ============================================================
// MARK: - ArrhythmiaAlgorithmsView.swift
// MARK: - ============================================================

private let reversibleCauses = [
    "Hypovolaemia", "Hypoxia", "Hydrogen ions (acidosis)", "Hypo/hyperkalaemia",
    "Hypoglycaemia", "Hypothermia", "Trauma", "Toxins",
    "Cardiac tamponade", "Tension pneumothorax", "Thrombosis"
]

// MARK: - Root View
struct ArrhythmiaAlgorithmsView: View {
    @State private var mode: Int = 0   // 0 = Tachycardia, 1 = Pulseless Arrest
    @State private var measurementMode: PatientMeasurementMode = .weight
    @State private var weightText: String = ""
    @State private var gaText: String = ""

    private var resolvedWeight: String {
        let kg = resolveWeightKg(mode: measurementMode, weightText: weightText, gaText: gaText)
        return kg > 0 ? fmtNum(kg, decimals: 2) : ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Cardiac Arrhythmias", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Text("Paediatric algorithms for tachycardia and pulseless arrest")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Picker("Mode", selection: $mode) {
                Text("Tachycardia").tag(0)
                Text("Pulseless Arrest").tag(1)
            }
            .pickerStyle(.segmented)

            WeightOrGAInput(
                label: "Weight or Gestational Age — for dosing",
                mode: $measurementMode,
                weightText: $weightText,
                gaText: $gaText
            )

            if mode == 0 {
                TachycardiaAlgorithmView(weight: resolvedWeight)
            } else {
                PulselessArrestAlgorithmView(weight: resolvedWeight)
            }

            ReversibleCausesCard()
            EKGReferenceCard()
        }
    }
}

// MARK: - Tachycardia Algorithm
private struct TachycardiaAlgorithmView: View {
    let weight: String
    var weightKg: Double { Double(weight) ?? 0 }

    var adenosineDose1: Double { weightKg * 0.1 }
    var adenosineDose2: Double { weightKg * 0.2 }
    var cardioversionLow: Double { weightKg * 1 }
    var cardioversionHigh: Double { weightKg * 2 }
    var unstableShock1: Double { weightKg * 1 }
    var unstableShock2: Double { weightKg * 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            AlgoDecision(
                question: "Look at QRS duration on ECG or cardiac monitor",
                color: .indigo,
                options: [
                    ("Narrow QRS", "Possible sinus tachycardia (infants usually < 220) or SVT (absent P waves, HR not variable, abrupt changes, HR > 220). Try vagal manoeuvres if this doesn't delay treatment."),
                    ("Wide QRS", "Possible VT")
                ]
            )

            AlgoDecision(
                question: "Is the patient stable or unstable? (cardiopulmonary compromise)",
                color: AppTheme.warning,
                options: [
                    ("Stable", "Consult cardiology about choice of treatment (e.g. amiodarone). Search and treat reversible causes. If refractory VT, consider cardioversion."),
                    ("Unstable — with cardiopulmonary compromise", "Immediate synchronized cardioversion. Sedate if possible, but do not delay cardioversion. Search and treat reversible causes. Consult cardiology for maintenance therapy.")
                ]
            )

            // Adenosine dosing (narrow QRS / SVT, stable)
            VStack(alignment: .leading, spacing: 6) {
                Text("IV Adenosine (narrow-complex SVT, stable)")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.accent)
                DoseCalcRow(label: "1st dose", formula: "0.1 mg/kg rapid bolus", result: weightKg > 0 ? "\(fmtNum(adenosineDose1, decimals: 2)) mg" : "— mg", color: AppTheme.accent)
                DoseCalcRow(label: "2nd dose", formula: "0.2 mg/kg", result: weightKg > 0 ? "\(fmtNum(adenosineDose2, decimals: 2)) mg" : "— mg", color: AppTheme.accent)
                Text("If haemodynamically unstable or adenosine ineffective: synchronized cardioversion.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(12)
            .background(AppTheme.accent.opacity(0.05))
            .cornerRadius(13)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.accent.opacity(0.2), lineWidth: 1))

            // Cardioversion dosing
            VStack(alignment: .leading, spacing: 6) {
                Text("Synchronized Cardioversion")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.danger)
                DoseCalcRow(
                    label: "If adenosine ineffective / unstable SVT",
                    formula: "0.5 – 1 J/kg, increase to 2 J/kg if ineffective",
                    result: weightKg > 0 ? "\(fmtNum(weightKg * 0.5, decimals: 1)) – \(fmtNum(cardioversionHigh, decimals: 1)) J" : "— J",
                    color: AppTheme.danger
                )
                DoseCalcRow(
                    label: "Unstable tachycardia (cardiopulmonary compromise)",
                    formula: "1 J/kg, increase to 2 J/kg if ineffective",
                    result: weightKg > 0 ? "\(fmtNum(unstableShock1, decimals: 1)) → \(fmtNum(unstableShock2, decimals: 1)) J" : "— J",
                    color: AppTheme.danger
                )
                Text("Sedate if possible but do not delay cardioversion. Search and treat reversible causes.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(12)
            .background(AppTheme.danger.opacity(0.05))
            .cornerRadius(13)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.danger.opacity(0.2), lineWidth: 1))
        }
    }
}

// MARK: - Pulseless Arrest Algorithm (top-level: shockable vs non-shockable)
private struct PulselessArrestAlgorithmView: View {
    let weight: String
    var weightKg: Double { Double(weight) ?? 0 }
    @State private var rhythmChoice: Int = 0 // 0 = unselected, 1 = shockable, 2 = non-shockable

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Immediate actions")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.textPrimary)
                bullet("Start CPR")
                bullet("Give 100% oxygen and ventilate")
                bullet("Attach ECG leads/defibrillator as soon as possible")
            }
            .padding(12)
            .background(AppTheme.surfaceElevated)
            .cornerRadius(13)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.accentMuted.opacity(0.5), lineWidth: 1))

            Text("Check rhythm — shockable?")
                .font(.subheadline.bold())
                .foregroundColor(.indigo)

            Picker("Rhythm", selection: $rhythmChoice) {
                Text("Select…").tag(0)
                Text("Shockable (VF/VT)").tag(1)
                Text("Non-shockable (Asystole/PEA)").tag(2)
            }
            .pickerStyle(.segmented)

            if rhythmChoice == 1 {
                ShockableArrestView(weightKg: weightKg)
            } else if rhythmChoice == 2 {
                NonShockableArrestView(weightKg: weightKg)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundColor(AppTheme.textSecondary)
            Text(text).font(.caption).foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Non-shockable (Asystole/PEA) — with running adrenaline timer
private struct NonShockableArrestView: View {
    let weightKg: Double
    @State private var cycles: Int = 0
    @State private var elapsedSeconds: Int = 0
    @State private var timerRunning = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var adrenalineDose: Double { weightKg * 0.1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Asystole / PEA")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.warning)
                bulletRow("High-quality CPR with ventilation")
                bulletRow("Obtain vascular access with minimal delay")
                bulletRow("Give adrenaline as soon as possible, then every 3–5 min")
                bulletRow("Check pulse and rhythm every 2 min")
                bulletRow("Search and treat reversible causes")
            }
            .padding(12)
            .background(AppTheme.warning.opacity(0.06))
            .cornerRadius(13)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.warning.opacity(0.2), lineWidth: 1))

            DoseCalcRow(
                label: "IV/IO Adrenaline",
                formula: "0.1 mL/kg 1:10,000 (0.01 mg/kg), q 3–5 min",
                result: weightKg > 0 ? "\(fmtNum(adrenalineDose, decimals: 2)) mL" : "— mL",
                color: AppTheme.warning
            )

            ArrestCycleTimer(cycles: $cycles, elapsedSeconds: $elapsedSeconds, timerRunning: $timerRunning, timer: timer, label: "Time since last adrenaline / rhythm check", color: AppTheme.warning)

            Text("Pulse present, HR > 60 and stable → begin post-resuscitation care.")
                .font(.caption)
                .foregroundColor(AppTheme.success)
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundColor(AppTheme.warning)
            Text(text).font(.caption).foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Shockable (VF/VT) — interactive shock stepper
private struct ShockableArrestView: View {
    let weightKg: Double
    @State private var shockCount: Int = 0
    @State private var cycles: Int = 0
    @State private var elapsedSeconds: Int = 0
    @State private var timerRunning = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var currentShockJoules: Double {
        // 1st shock 2-4 J/kg, all subsequent shocks 4 J/kg
        shockCount == 0 ? weightKg * 2 : weightKg * 4
    }
    var currentShockJoulesHigh: Double { weightKg * 4 }
    var adrenalineDose: Double { weightKg * 0.1 }
    var amiodaroneDose: Double { weightKg * 5 }
    var lignocaineDose: Double { weightKg * 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pulseless VF/VT")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.danger)
                bulletRow("Give 100% oxygen and ventilate; start CPR; attach defibrillator immediately")
                bulletRow("Minimise time between chest compressions and shock delivery")
                bulletRow("CPR 2 min, then check pulse and rhythm — shockable?")
            }
            .padding(12)
            .background(AppTheme.danger.opacity(0.06))
            .cornerRadius(13)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.danger.opacity(0.2), lineWidth: 1))

            // Shock stepper
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Shock counter")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Text("\(shockCount) delivered")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.danger)
                }

                HStack(spacing: 10) {
                    Text(nextShockLabel)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.danger)
                    Spacer()
                    Button {
                        withAnimation { shockCount += 1 }
                    } label: {
                        Label("Deliver Shock", systemImage: "bolt.fill")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(AppTheme.danger)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    if shockCount > 0 {
                        Button {
                            withAnimation { shockCount -= 1 }
                        } label: {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }

                if shockCount > 0 {
                    Text(afterShockGuidance)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(12)
            .background(AppTheme.surfaceElevated)
            .cornerRadius(13)
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.danger.opacity(0.25), lineWidth: 1))

            ArrestCycleTimer(cycles: $cycles, elapsedSeconds: $elapsedSeconds, timerRunning: $timerRunning, timer: timer, label: "CPR cycle timer (resume CPR immediately after each shock)", color: AppTheme.danger)

            DoseCalcRow(label: "IV/IO Adrenaline", formula: "0.1 mL/kg (0.01 mg/kg) q 3–5 min, or every other shock", result: weightKg > 0 ? "\(fmtNum(adrenalineDose, decimals: 2)) mL" : "— mL", color: AppTheme.purple)
            DoseCalcRow(label: "IV/IO Amiodarone", formula: "5 mg/kg, up to 3 times (after 3rd/5th/7th shock)", result: weightKg > 0 ? "\(fmtNum(amiodaroneDose, decimals: 1)) mg" : "— mg", color: AppTheme.purple)
            DoseCalcRow(label: "IV/IO Lignocaine (alternative)", formula: "1 mg/kg, then infusion 20–50 mcg/kg/min", result: weightKg > 0 ? "\(fmtNum(lignocaineDose, decimals: 1)) mg" : "— mg", color: AppTheme.purple)
            DoseCalcRow(label: "Magnesium sulphate (Torsades)", formula: "50 mg/kg", result: weightKg > 0 ? "\(fmtNum(weightKg * 50, decimals: 0)) mg" : "— mg", color: AppTheme.purple)

            Text("Consider increasing shock to 10 J/kg for refractory VF. Look for and treat reversible causes.")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)

            if shockCount > 0 {
                Button {
                    withAnimation { shockCount = 0; cycles = 0; elapsedSeconds = 0; timerRunning = false }
                } label: {
                    Label("Reset Shock Counter", systemImage: "arrow.counterclockwise")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.danger)
                }
            }
        }
    }

    private var nextShockLabel: String {
        guard weightKg > 0 else { return "— J" }
        if shockCount == 0 {
            return "\(fmtNum(weightKg * 2, decimals: 1)) – \(fmtNum(weightKg * 4, decimals: 1)) J"
        }
        return "\(fmtNum(currentShockJoulesHigh, decimals: 1)) J"
    }

    private var afterShockGuidance: String {
        switch shockCount {
        case 1, 2: return "Resume CPR immediately. Give adrenaline (every other shock)."
        case 3: return "Resume CPR immediately. Consider amiodarone 5 mg/kg or lignocaine 1 mg/kg."
        case 4: return "Resume CPR immediately. Give adrenaline."
        case 5: return "Resume CPR immediately. Consider repeat amiodarone or lignocaine infusion."
        default: return "Resume CPR immediately. Reassess rhythm and continue drug cycle."
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundColor(AppTheme.danger)
            Text(text).font(.caption).foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Reusable CPR cycle timer
private struct ArrestCycleTimer: View {
    @Binding var cycles: Int
    @Binding var elapsedSeconds: Int
    @Binding var timerRunning: Bool
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    let label: String
    var color: Color = AppTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(AppTheme.textSecondary)
            HStack {
                Text(timeString)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Spacer()
                Button {
                    timerRunning.toggle()
                } label: {
                    Image(systemName: timerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(color)
                }
                Button {
                    elapsedSeconds = 0; timerRunning = false; cycles = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            Text("2-min cycles completed: \(cycles)")
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(12)
        .background(color.opacity(0.05))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.2), lineWidth: 1))
        .onReceive(timer) { _ in
            guard timerRunning else { return }
            elapsedSeconds += 1
            if elapsedSeconds % 120 == 0 { cycles += 1 }
        }
    }

    private var timeString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Shared decision display
private struct AlgoDecision: View {
    let question: String
    let color: Color
    let options: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "diamond.fill").font(.caption).foregroundColor(color)
                Text(question).font(.subheadline.bold()).foregroundColor(color)
            }
            ForEach(options, id: \.0) { opt in
                VStack(alignment: .leading, spacing: 2) {
                    Text(opt.0).font(.caption.bold()).foregroundColor(AppTheme.textPrimary)
                    Text(opt.1).font(.caption).foregroundColor(AppTheme.textSecondary)
                }
                .padding(8)
                .background(color.opacity(0.06))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(color.opacity(0.04))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.18), lineWidth: 1))
    }
}

private struct ReversibleCausesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Reversible Causes (the 4 H's & 4 T's + 3)", systemImage: "magnifyingglass", color: .indigo)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(reversibleCauses, id: \.self) { cause in
                    Text(cause)
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.vertical, 5).padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.indigo.opacity(0.06))
                        .cornerRadius(7)
                }
            }
        }
        .padding(12)
        .background(AppTheme.surfaceElevated)
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.accentMuted.opacity(0.5), lineWidth: 1))
    }
}

private struct EKGReferenceCard: View {
    private let refs: [(String, String)] = [
        ("Supraventricular Tachycardia (SVT)", "https://www.ekgstripsearch.com/SVT.htm"),
        ("Ventricular Tachycardia (VT)", "https://www.ekgstripsearch.com/VT.htm"),
        ("Ventricular Fibrillation (VF)", "https://www.ekgstripsearch.com/VFIB.htm")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "ECG Strip References", systemImage: "waveform", color: AppTheme.teal)
            ForEach(refs, id: \.0) { ref in
                HStack {
                    Text(ref.0).font(.caption).foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if let url = URL(string: ref.1) {
                        Link("View", destination: url)
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.teal)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(AppTheme.surfaceElevated)
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.accentMuted.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - ============================================================
// MARK: - NeonatalEmergenciesHomeView.swift
// MARK: - ============================================================

private struct EmergencyItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
}

private let neonatalEmergencies: [EmergencyItem] = [
    EmergencyItem(title: "Cardiac Arrhythmias", subtitle: "Tachycardia & pulseless arrest algorithms", systemImage: "waveform.path.ecg", color: AppTheme.danger),
    EmergencyItem(title: "Neonatal ECMO Activation", subtitle: "Standard & eCPR activation protocol", systemImage: "waveform.path.ecg.rectangle", color: AppTheme.purple)
]

// MARK: - Home View
struct NeonatalEmergenciesHomeView: View {
    @Binding var weight: String

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.background, AppTheme.backgroundDeep], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Conditions & Checklists")
                            .font(.largeTitle.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Tap a category to open its checklist")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 8)

                    // ── Neonatal Emergencies ─────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Special Resuscitation Protocols", systemImage: "exclamationmark.triangle.fill", color: AppTheme.danger)

                        ForEach(neonatalEmergencies) { item in
                            NavigationLink {
                                destinationView(for: item.title)
                            } label: {
                                EmergencyRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider().background(AppTheme.accentMuted.opacity(0.5))

                    // ── High-risk Deliveries ─────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Checklists for High-risk Deliveries", systemImage: "list.bullet.rectangle.fill", color: AppTheme.accent)

                        // ⬇️ Existing conditions list is embedded here.
                        // Replace/adjust this call if your CommonConditionsView
                        // signature differs from `CommonConditionsView(weight: $weight)`.
                        CommonConditionsView(weight: $weight)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    @ViewBuilder
    private func destinationView(for title: String) -> some View {
        ZStack {
            LinearGradient(colors: [AppTheme.background, AppTheme.backgroundDeep], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if title == "Cardiac Arrhythmias" {
                        ArrhythmiaAlgorithmsView()
                    } else {
                        ECMOActivationView()
                    }
                    Spacer(minLength: 24)
                }
                .padding(16)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Emergency Row
private struct EmergencyRow: View {
    let item: EmergencyItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(item.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(item.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.textPrimary)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(14)
        .background(AppTheme.surfaceElevated)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(item.color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - ============================================================
// MARK: - ContentView.swift
// MARK: - ============================================================

struct ContentView: View {

    // Patient inputs (shared across tabs). The team wants exactly one of
    // weight/gestational-age captured, ever — WeightOrGAInput enforces
    // that choice and effectiveWeightKg below resolves it (estimating
    // from GA via the Fenton chart when weight itself isn't known).
    @State private var patientMeasurementMode: PatientMeasurementMode = .weight
    @State private var weight = ""
    @State private var gestationalAge = ""
    @EnvironmentObject private var copilotContextStore: CopilotContextStore
    @EnvironmentObject private var authManager: AuthManager
    @State private var showAccountSheet = false

    @State private var selectedTab = 0

    // Collapsible section states
    @State private var showEquipment  = false
    @State private var showDrugs      = false
    @State private var showApgar      = false
    @State private var showThompson   = false
    @State private var showAlgorithm  = false
    @State private var showInfusions  = false
    @State private var showRespiratory = false
    @State private var showBallard    = false

    // APGAR state
    @State private var apgarAppearance  = 0
    @State private var apgarPulse       = 0
    @State private var apgarGrimace     = 0
    @State private var apgarActivity    = 0
    @State private var apgarRespiration = 0

    // Thompson HIE score — one shared model so the calculator on the
    // Resuscitation tab and the one inside the HIE condition page always
    // show the same score.
    @StateObject private var thompsonScore = ThompsonScoreModel()

    // Respiratory indices + Ballard: models live here so entered values survive
    // the collapsible sections being closed and reopened.
    @StateObject private var respiratory = RespiratoryIndicesModel()
    @StateObject private var ballard = BallardModel()

    var weightKg: Double { Double(weight) ?? 0 }
    var gaWeeks: Int { Int(gestationalAge) ?? 0 }

    /// The number every weight-based calculator on this screen actually
    /// uses: the entered weight if that's what was captured, otherwise
    /// the Fenton-chart estimate from gestational age.
    var effectiveWeightKg: Double {
        resolveWeightKg(mode: patientMeasurementMode, weightText: weight, gaText: gestationalAge)
    }

    /// Downstream screens that still take a plain weight string (Conditions
    /// tab, Infusions) get this instead of `$weight` directly, so they see
    /// the estimate too when only gestational age was entered. Read-only
    /// while in gestational-age mode — there's nothing sensible to write
    /// back to.
    private var resolvedWeightBinding: Binding<String> {
        Binding(
            get: {
                effectiveWeightKg > 0 ? fmtNum(effectiveWeightKg, decimals: 2) : ""
            },
            set: { newValue in
                if patientMeasurementMode == .weight { weight = newValue }
            }
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── Tab 1: Resuscitation ─────────────────────────────────────
            resuscitationTab
                .tabItem {
                    Label("Resuscitation", systemImage: "stethoscope")
                }
                .tag(0)

            // ── Tab 2: Conditions (Neonatal Emergencies + High-risk Deliveries) ──
            NavigationView {
                NeonatalEmergenciesHomeView(weight: resolvedWeightBinding)
                    .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Conditions", systemImage: "list.bullet.rectangle")
            }
            .tag(1)

            // ── Tab 3: Infusions ─────────────────────────────────────────
            infusionsTab
                .tabItem {
                    Label("Infusions", systemImage: "drop.fill")
                }
                .tag(2)
        }
        .tint(AppTheme.accent)
        .environmentObject(thompsonScore)
        .overlay(CopilotFloatingLayer())
        // Floating Done bar tracks the keyboard frame, so it works on every tab.
        // (A `.keyboard` toolbar on a bare TabView never renders — that was the bug.)
        .keyboardDoneBar()
        .sheet(isPresented: $showAccountSheet) {
            AccountSheet()
        }
        .onAppear { syncCopilotContext() }
        .onChange(of: weight) { _ in syncCopilotContext() }
        .onChange(of: gestationalAge) { _ in syncCopilotContext() }
        .onChange(of: apgarAppearance) { _ in syncCopilotContext() }
        .onChange(of: apgarPulse) { _ in syncCopilotContext() }
        .onChange(of: apgarGrimace) { _ in syncCopilotContext() }
        .onChange(of: apgarActivity) { _ in syncCopilotContext() }
        .onChange(of: apgarRespiration) { _ in syncCopilotContext() }
        .onChange(of: selectedTab) { tab in
            let screens = ["Resuscitation", "Conditions", "Infusions"]
            copilotContextStore.currentScreen = (tab >= 0 && tab < screens.count) ? screens[tab] : "Resuscitation"
        }
    }

    /// Publishes the current patient inputs into the shared copilot context
    /// store. The copilot never reads app state directly — this is the only
    /// path patient data takes to reach it, keeping it read-only from the
    /// copilot's side and easy to audit.
    private func syncCopilotContext() {
        copilotContextStore.weightKg = effectiveWeightKg
        copilotContextStore.gaWeeks = gaWeeks
        let hasApgarInput = apgarAppearance + apgarPulse + apgarGrimace + apgarActivity + apgarRespiration > 0
        copilotContextStore.apgar = hasApgarInput
            ? APGARSnapshot(appearance: apgarAppearance, pulse: apgarPulse, grimace: apgarGrimace,
                             activity: apgarActivity, respiration: apgarRespiration)
            : nil
    }

    // MARK: - Resuscitation Tab
    var resuscitationTab: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    AppTheme.background,
                    AppTheme.backgroundDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // ── Header ───────────────────────────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Neonatal Resuscitation")
                                .font(.largeTitle.bold())
                                .foregroundColor(AppTheme.textPrimary)
                            Text("SNRC 2026 Guidelines")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            showAccountSheet = true
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppTheme.accent)
                        }
                        .accessibilityLabel("Account")
                        .padding(.top, 6)
                    }
                    .padding(.top, AppTheme.Spacing.sm)

                    // ── Patient Details ──────────────────────────────────
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Label("Patient Details", systemImage: "person.crop.circle")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        WeightOrGAInput(
                            label: "Weight or Gestational Age",
                            mode: $patientMeasurementMode,
                            weightText: $weight,
                            gaText: $gestationalAge
                        )
                    }
                    .sectionCard()

                    // ── Equipment ────────────────────────────────────────
                    CollapsibleSection(
                        title: "Equipment",
                        systemImage: "cross.case.fill",
                        accentColor: AppTheme.teal,
                        isExpanded: $showEquipment
                    ) {
                        EquipmentSectionView(weightKg: effectiveWeightKg, gaWeeks: gaWeeks)
                    }

                    // ── Drugs ────────────────────────────────────────────
                    CollapsibleSection(
                        title: "Resuscitation Drugs",
                        systemImage: "pills.fill",
                        accentColor: AppTheme.danger,
                        isExpanded: $showDrugs
                    ) {
                        DrugsSectionView(weightKg: effectiveWeightKg)
                    }

                    // ── Infusions ────────────────────────────────────────
                    CollapsibleSection(
                        title: "Infusions",
                        systemImage: "drop.fill",
                        accentColor: AppTheme.purple,
                        isExpanded: $showInfusions
                    ) {
                        InfusionsSectionView(weight: resolvedWeightBinding)
                    }

                    // ── APGAR ────────────────────────────────────────────
                    CollapsibleSection(
                        title: "APGAR Score Calculator",
                        systemImage: "heart.text.square.fill",
                        accentColor: AppTheme.success,
                        isExpanded: $showApgar
                    ) {
                        APGARSectionView(
                            appearance: $apgarAppearance,
                            pulse: $apgarPulse,
                            grimace: $apgarGrimace,
                            activity: $apgarActivity,
                            respiration: $apgarRespiration
                        )
                    }

                    // ── Thompson Score ───────────────────────────────────
                    CollapsibleSection(
                        title: "Thompson HIE Score Calculator",
                        systemImage: "brain.head.profile",
                        accentColor: AppTheme.warning,
                        isExpanded: $showThompson
                    ) {
                        ThompsonScoreSectionView()
                    }

                    // ── Respiratory indices (A-aDO₂ / RI / OI) ───────────
                    CollapsibleSection(
                        title: "A-aDO₂ · Respiratory & Oxygenation Index",
                        systemImage: "lungs.fill",
                        accentColor: AppTheme.teal,
                        isExpanded: $showRespiratory
                    ) {
                        RespiratoryIndicesSectionView(model: respiratory)
                    }

                    // ── Ballard score ────────────────────────────────────
                    CollapsibleSection(
                        title: "Ballard Score (Gestational Age)",
                        systemImage: "calendar.badge.clock",
                        accentColor: AppTheme.purple,
                        isExpanded: $showBallard
                    ) {
                        BallardScoreSectionView(model: ballard) { weeks in
                            patientMeasurementMode = .gestationalAge
                            gestationalAge = String(weeks)
                        }
                    }

                    // ── Algorithm ────────────────────────────────────────
                    CollapsibleSection(
                        title: "Resuscitation Algorithm",
                        systemImage: "waveform.path.ecg",
                        accentColor: AppTheme.accent,
                        isExpanded: $showAlgorithm
                    ) {
                        ResuscitationAlgorithmView()
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Infusions Tab
    var infusionsTab: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.backgroundDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Infusions")
                            .font(.largeTitle.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Weight-based dilution & rate calculator")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 8)

                    InfusionsSectionView(weight: resolvedWeightBinding)
                        .sectionCard()

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Account Sheet
private struct AccountSheet: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.xl) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(AppTheme.accent)
                        Text(authManager.displayEmail)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.top, AppTheme.Spacing.xl)

                    Button(role: .destructive) {
                        authManager.signOut()
                        dismiss()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .background(AppTheme.danger.opacity(0.12))
                    .foregroundColor(AppTheme.danger)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CopilotContextStore())
        .environmentObject(AuthManager())
}
