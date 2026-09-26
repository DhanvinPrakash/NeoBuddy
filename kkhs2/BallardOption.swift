//
//  BallardOption.swift
//  kkhs2
//
//  Created by dhanvin_macbook on 24/9/26.
//


//
//  BallardScore.swift
//  kkhs2
//
//  New Ballard Score (Ballard et al., J Pediatr 1991;119:417–423) — 6
//  neuromuscular + 6 physical signs → total → estimated gestational age.
//
//  Score → weeks follows the printed chart: -10 = 20 wk, 0 = 24 wk, 50 = 44 wk,
//  i.e. +2 weeks per +5 points (weeks = 24 + 0.4 × score).
//
//  Like the Thompson calculator, every sign starts UNSCORED and the result is
//  labelled provisional until all 12 are answered. Descriptions are condensed —
//  verify against the printed chart your unit uses.
//

import SwiftUI
import Combine

struct BallardOption: Identifiable {
    let score: Int
    let text: String
    var id: Int { score }
}

struct BallardSign: Identifiable {
    enum Group { case neuromuscular, physical }
    let id: String
    let title: String
    let group: Group
    let options: [BallardOption]
}

private func opts(_ pairs: [(Int, String)]) -> [BallardOption] {
    pairs.map { BallardOption(score: $0.0, text: $0.1) }
}

private let ballardNeuromuscular: [BallardSign] = [
    BallardSign(id: "posture", title: "Posture", group: .neuromuscular, options: opts([
        (0, "Arms & legs extended"),
        (1, "Slight hip/knee flexion"),
        (2, "Legs flexed, arms extended"),
        (3, "Arms slightly flexed, legs flexed & abducted"),
        (4, "Full flexion of arms & legs")])),
    BallardSign(id: "window", title: "Square window (wrist)", group: .neuromuscular, options: opts([
        (-1, "> 90°"), (0, "90°"), (1, "60°"), (2, "45°"), (3, "30°"), (4, "0°")])),
    BallardSign(id: "recoil", title: "Arm recoil", group: .neuromuscular, options: opts([
        (0, "180°"), (1, "140–180°"), (2, "110–140°"), (3, "90–110°"), (4, "< 90°")])),
    BallardSign(id: "popliteal", title: "Popliteal angle", group: .neuromuscular, options: opts([
        (-1, "180°"), (0, "160°"), (1, "140°"), (2, "120°"), (3, "100°"), (4, "90°"), (5, "< 90°")])),
    BallardSign(id: "scarf", title: "Scarf sign", group: .neuromuscular, options: opts([
        (-1, "Elbow reaches opposite axilla"),
        (0, "Elbow at opposite anterior axillary line"),
        (1, "Elbow between opposite axillary line and midline"),
        (2, "Elbow at midline"),
        (3, "Elbow between midline and same-side axillary line"),
        (4, "Elbow barely crosses the chest")])),
    BallardSign(id: "heelear", title: "Heel to ear", group: .neuromuscular, options: opts([
        (-1, "Heel at / near ear"),
        (0, "Heel at nose"),
        (1, "Heel at chin"),
        (2, "Heel at nipple line"),
        (3, "Heel at umbilical area"),
        (4, "Heel at femoral crease")]))
]

private let ballardPhysical: [BallardSign] = [
    BallardSign(id: "skin", title: "Skin", group: .physical, options: opts([
        (-1, "Sticky, friable, transparent"),
        (0, "Gelatinous, red, translucent"),
        (1, "Smooth, pink, visible veins"),
        (2, "Superficial peeling / rash, few veins"),
        (3, "Cracking, pale areas, rare veins"),
        (4, "Parchment, deep cracking, no vessels"),
        (5, "Leathery, cracked, wrinkled")])),
    BallardSign(id: "lanugo", title: "Lanugo", group: .physical, options: opts([
        (-1, "None"), (0, "Sparse"), (1, "Abundant"), (2, "Thinning"), (3, "Bald areas"), (4, "Mostly bald")])),
    BallardSign(id: "plantar", title: "Plantar surface", group: .physical, options: opts([
        (-2, "Heel–toe < 40 mm"),
        (-1, "Heel–toe 40–50 mm"),
        (0, "> 50 mm, no crease"),
        (1, "Faint red marks"),
        (2, "Anterior transverse crease only"),
        (3, "Creases over anterior 2/3"),
        (4, "Creases over entire sole")])),
    BallardSign(id: "breast", title: "Breast", group: .physical, options: opts([
        (-1, "Imperceptible"),
        (0, "Barely perceptible"),
        (1, "Flat areola, no bud"),
        (2, "Stippled areola, 1–2 mm bud"),
        (3, "Raised areola, 3–4 mm bud"),
        (4, "Full areola, 5–10 mm bud")])),
    BallardSign(id: "eyeear", title: "Eye / ear", group: .physical, options: opts([
        (-2, "Lids fused tightly"),
        (-1, "Lids fused loosely"),
        (0, "Lids open, pinna flat, stays folded"),
        (1, "Slightly curved pinna, soft, slow recoil"),
        (2, "Well-curved pinna, soft, ready recoil"),
        (3, "Formed & firm, instant recoil"),
        (4, "Thick cartilage, ear stiff")]))
]

private let ballardGenitalsMale = BallardSign(id: "genitals", title: "Genitals (male)", group: .physical, options: opts([
    (-1, "Scrotum flat, smooth"),
    (0, "Scrotum empty, faint rugae"),
    (1, "Testes in upper canal, rare rugae"),
    (2, "Testes descending, few rugae"),
    (3, "Testes down, good rugae"),
    (4, "Testes pendulous, deep rugae")]))

private let ballardGenitalsFemale = BallardSign(id: "genitals", title: "Genitals (female)", group: .physical, options: opts([
    (-1, "Clitoris prominent, labia flat"),
    (0, "Clitoris prominent, small labia minora"),
    (1, "Clitoris prominent, enlarging minora"),
    (2, "Majora & minora equally prominent"),
    (3, "Majora large, minora small"),
    (4, "Majora cover clitoris & minora")]))

// MARK: - Model

final class BallardModel: ObservableObject {
    enum Sex: String, CaseIterable, Identifiable {
        case male = "Male", female = "Female"
        var id: String { rawValue }
    }

    /// sign id -> chosen score. Missing key = not yet assessed.
    @Published var selected: [String: Int] = [:]
    @Published var sex: Sex? = nil

    var neuromuscularSigns: [BallardSign] { ballardNeuromuscular }

    var physicalSigns: [BallardSign] {
        var signs = ballardPhysical
        if let sex { signs.append(sex == .male ? ballardGenitalsMale : ballardGenitalsFemale) }
        return signs
    }

    static let signCount = 12
    private var activeIDs: Set<String> { Set((neuromuscularSigns + physicalSigns).map(\.id)) }

    var scoredCount: Int { selected.keys.filter { activeIDs.contains($0) }.count }
    var isComplete: Bool { scoredCount == Self.signCount }

    private func subtotal(_ signs: [BallardSign]) -> Int {
        signs.reduce(0) { $0 + (selected[$1.id] ?? 0) }
    }
    var neuromuscularTotal: Int { subtotal(neuromuscularSigns) }
    var physicalTotal: Int { subtotal(physicalSigns) }
    var total: Int { neuromuscularTotal + physicalTotal }

    /// Printed chart: -10 → 20 wk … 50 → 44 wk (2 weeks per 5 points).
    var gestationalWeeks: Double {
        min(44, max(20, 24 + 0.4 * Double(total)))
    }
    var roundedWeeks: Int { Int(gestationalWeeks.rounded()) }

    func select(sign: String, score: Int) {
        if selected[sign] == score { selected.removeValue(forKey: sign) }
        else { selected[sign] = score }
    }

    func setSex(_ new: Sex) {
        guard sex != new else { return }
        sex = new
        selected.removeValue(forKey: "genitals")   // options differ per sex
    }

    func reset() { selected = [:]; sex = nil }
}

// MARK: - View

struct BallardScoreSectionView: View {
    @ObservedObject var model: BallardModel
    /// Called with the rounded estimate when the user taps "Use as gestational age".
    var onUseGestationalAge: ((Int) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryCard

            groupHeader("Neuromuscular maturity", systemImage: "figure.walk", subtotal: model.neuromuscularTotal)
            ForEach(model.neuromuscularSigns) { signRow($0) }

            groupHeader("Physical maturity", systemImage: "hand.raised.fingers.spread.fill", subtotal: model.physicalTotal)
            sexPicker
            ForEach(model.physicalSigns) { signRow($0) }
            if model.sex == nil {
                Label("Select sex to score genitals", systemImage: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.warning)
            }

            if model.scoredCount > 0 {
                Button {
                    withAnimation { model.reset() }
                } label: {
                    Label("Reset Ballard score", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.danger)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                note("Total −10 to 50 → 20 to 44 weeks (2 wk per 5 points)")
                note("Most accurate within 48 h of birth · typical error ± 2 wk")
                note("Descriptions condensed — verify against the printed chart")
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.warning.opacity(0.07))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.warning.opacity(0.2), lineWidth: 1))
        }
    }

    // MARK: Summary

    private var summaryCard: some View {
        let started = model.scoredCount > 0
        let color = model.isComplete ? AppTheme.success : AppTheme.accent
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.isComplete ? "Estimated gestational age" : "Provisional estimate")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(started ? "\(model.roundedWeeks)" : "—")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(started ? color : AppTheme.textSecondary)
                        Text("wk")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Score \(model.total)")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textPrimary)
                    Text("\(model.scoredCount)/\(BallardModel.signCount) signs scored")
                        .font(.caption.bold())
                        .foregroundColor(model.isComplete ? AppTheme.success : AppTheme.warning)
                }
            }

            if model.isComplete, let onUse = onUseGestationalAge {
                Button {
                    Haptics.mediumTap()
                    onUse(model.roundedWeeks)
                } label: {
                    Label("Use \(model.roundedWeeks) wk as gestational age", systemImage: "arrow.up.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(AppTheme.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(color.opacity(0.07))
        .cornerRadius(14)
    }

    // MARK: Pieces

    private func groupHeader(_ title: String, systemImage: String, subtotal: Int) -> some View {
        HStack {
            SectionHeader(title: title, systemImage: systemImage, color: AppTheme.purple)
            Spacer()
            Text("\(subtotal)")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.top, 4)
    }

    private var sexPicker: some View {
        HStack(spacing: 6) {
            ForEach(BallardModel.Sex.allCases) { s in
                let on = model.sex == s
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { model.setSex(s) }
                } label: {
                    Text(s.rawValue)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(on ? AppTheme.accent : AppTheme.accent.opacity(0.09))
                        .foregroundColor(on ? .white : AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
    }

    private func signRow(_ sign: BallardSign) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sign.title)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)
            VStack(spacing: 5) {
                ForEach(sign.options) { option in
                    chip(sign: sign, option: option)
                }
            }
        }
    }

    private func chip(sign: BallardSign, option: BallardOption) -> some View {
        let isSelected = model.selected[sign.id] == option.score
        return Button {
            Haptics.checklistTap()
            withAnimation(.easeInOut(duration: 0.15)) {
                model.select(sign: sign.id, score: option.score)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(option.score)")
                    .font(.caption.weight(.heavy))
                    .frame(width: 18, alignment: .trailing)
                Text(option.text)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.09))
            .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(sign.title): \(option.text), \(option.score) points")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
