//
//  RespiratoryIndicesModel.swift
//  kkhs2
//
//  Created by dhanvin_macbook on 24/9/26.
//


//
//  RespiratoryIndices.swift
//  kkhs2
//
//  A-aDO₂ ("AaO2" gradient), Respiratory Index (RI) and Oxygenation Index (OI).
//
//  A-aDO₂ = FiO₂ × (Patm − PH₂O) − PaCO₂ / RQ − PaO₂
//  RI     = A-aDO₂ / PaO₂
//  a/A    = PaO₂ / PAO₂
//  OI     = MAP (cmH₂O) × FiO₂ (%) / PaO₂ (mmHg)
//
//  Assumes Patm 760 mmHg (sea level), PH₂O 47 mmHg, RQ 0.8.
//  State lives in a model owned by ContentView so it survives the
//  collapsible section being closed and reopened.
//

import SwiftUI
import Combine

final class RespiratoryIndicesModel: ObservableObject {

    enum GasUnit: String, CaseIterable, Identifiable {
        case kPa = "kPa"
        case mmHg = "mmHg"
        var id: String { rawValue }
    }

    @Published var unit: GasUnit = .kPa
    @Published var fio2Text = ""     // percent, 21–100
    @Published var pao2Text = ""
    @Published var paco2Text = ""
    @Published var mapText = ""      // cmH₂O

    static let kPaToMmHg = 7.50062
    static let atmosphericMmHg = 760.0
    static let waterVapourMmHg = 47.0
    static let respiratoryQuotient = 0.8

    private func parse(_ s: String) -> Double? {
        Double(s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }

    // MARK: Inputs normalised to mmHg / fractions

    var fio2Fraction: Double? {
        guard let p = parse(fio2Text), (21...100).contains(p) else { return nil }
        return p / 100
    }
    var pao2MmHg: Double? {
        guard let v = parse(pao2Text), v > 0 else { return nil }
        return unit == .kPa ? v * Self.kPaToMmHg : v
    }
    var paco2MmHg: Double? {
        guard let v = parse(paco2Text), v > 0 else { return nil }
        return unit == .kPa ? v * Self.kPaToMmHg : v
    }
    var mapCmH2O: Double? {
        guard let v = parse(mapText), v > 0 else { return nil }
        return v
    }

    // MARK: Results

    var alveolarO2MmHg: Double? {
        guard let f = fio2Fraction, let pc = paco2MmHg else { return nil }
        let pA = f * (Self.atmosphericMmHg - Self.waterVapourMmHg) - pc / Self.respiratoryQuotient
        return pA > 0 ? pA : nil
    }
    var aaGradientMmHg: Double? {
        guard let pA = alveolarO2MmHg, let pa = pao2MmHg else { return nil }
        return pA - pa
    }
    var respiratoryIndex: Double? {
        guard let g = aaGradientMmHg, let pa = pao2MmHg else { return nil }
        return g / pa
    }
    var aARatio: Double? {
        guard let pA = alveolarO2MmHg, let pa = pao2MmHg else { return nil }
        return pa / pA
    }
    var oxygenationIndex: Double? {
        guard let f = fio2Fraction, let map = mapCmH2O, let pa = pao2MmHg else { return nil }
        return map * (f * 100) / pa
    }

    /// Neutral severity bands — thresholds vary between units, so the view
    /// tells the user to confirm against local protocol.
    var oiBand: (label: String, color: Color)? {
        guard let oi = oxygenationIndex else { return nil }
        switch oi {
        case ..<15:   return ("Below 15", AppTheme.success)
        case 15..<25: return ("15–25 · moderate–severe", AppTheme.warning)
        case 25..<40: return ("25–40 · severe", AppTheme.danger)
        default:      return ("≥ 40 · very severe", AppTheme.danger)
        }
    }

    func pressureText(_ mmHg: Double) -> String {
        unit == .kPa
            ? "\(fmtNum(mmHg / Self.kPaToMmHg, decimals: 1)) kPa"
            : "\(fmtNum(mmHg, decimals: 0)) mmHg"
    }

    var hasAnyInput: Bool {
        !(fio2Text.isEmpty && pao2Text.isEmpty && paco2Text.isEmpty && mapText.isEmpty)
    }

    func reset() {
        fio2Text = ""; pao2Text = ""; paco2Text = ""; mapText = ""
    }
}

struct RespiratoryIndicesSectionView: View {
    @ObservedObject var model: RespiratoryIndicesModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Picker("Gas units", selection: $model.unit) {
                ForEach(RespiratoryIndicesModel.GasUnit.allCases) { u in
                    Text(u.rawValue).tag(u)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                CalcNumberField(label: "FiO₂ (%)", placeholder: "21–100", text: $model.fio2Text)
                CalcNumberField(label: "MAP (cmH₂O)", placeholder: "e.g. 10", text: $model.mapText)
            }
            HStack(spacing: 10) {
                CalcNumberField(label: "PaO₂ (\(model.unit.rawValue))", placeholder: model.unit == .kPa ? "e.g. 8.5" : "e.g. 65", text: $model.pao2Text)
                CalcNumberField(label: "PaCO₂ (\(model.unit.rawValue))", placeholder: model.unit == .kPa ? "e.g. 6.0" : "e.g. 45", text: $model.paco2Text)
            }

            results

            if model.hasAnyInput {
                Button {
                    withAnimation { model.reset() }
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.danger)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                note("Use an arterial gas (PaO₂ must be arterial)")
                note("Assumes Patm 760 mmHg, PH₂O 47 mmHg, RQ 0.8")
                note("A-aDO₂ needs FiO₂ + PaO₂ + PaCO₂; OI needs FiO₂ + MAP + PaO₂")
                note("Confirm OI thresholds against your unit protocol")
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.warning.opacity(0.07))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.warning.opacity(0.2), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var results: some View {
        VStack(spacing: 8) {
            resultRow("A-aDO₂ gradient", model.aaGradientMmHg.map { model.pressureText($0) })
            resultRow("Respiratory Index (RI)", model.respiratoryIndex.map { fmtNum($0, decimals: 2) })
            resultRow("a/A ratio", model.aARatio.map { fmtNum($0, decimals: 2) })
            HStack {
                resultRow("Oxygenation Index (OI)", model.oxygenationIndex.map { fmtNum($0, decimals: 1) },
                          color: model.oiBand?.color ?? AppTheme.accent)
            }
            if let band = model.oiBand {
                HStack {
                    Spacer()
                    PillBadge(text: "OI \(band.label)", color: band.color)
                }
            }
        }
    }

    private func resultRow(_ title: String, _ value: String?, color: Color = AppTheme.accent) -> some View {
        InfoRow(title: title, value: value ?? "—", valueColor: value == nil ? AppTheme.textSecondary : color)
    }

    private func note(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("•").foregroundColor(AppTheme.warning)
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

/// Numeric field styled like the rest of the app's inputs.
struct CalcNumberField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(AppTheme.textSecondary)
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(AppTheme.surface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.accentMuted.opacity(0.6), lineWidth: 1))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}