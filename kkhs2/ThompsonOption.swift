//
//  ThompsonOption.swift
//  kkhs2
//
//  Thompson HIE score calculator (Thompson et al., 1997).
//  Nine bedside signs -> total out of 22.
//
//  Built on the shared ScoreSign / ScoreOption / SignScoreModel / ScoreChip
//  engine in ScoreEngine.swift. This file holds only what's specific to
//  Thompson: the nine signs, the severity bands, and the grid-of-chips layout.
//
//  State lives in a ThompsonScoreModel owned by ContentView and passed
//  down via .environmentObject, so the calculator on the Resuscitation
//  tab and the one inside the HIE condition page show the SAME score.
//

import SwiftUI
import Combine

// MARK: - Sign definitions

let thompsonSigns: [ScoreSign] = [
    ScoreSign(id: "tone", title: "Tone", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Hypertonia"),
        .init(score: 2, label: "Hypotonia"),
        .init(score: 3, label: "Flaccid")
    ]),
    ScoreSign(id: "loc", title: "Level of consciousness", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Hyper-alert, staring"),
        .init(score: 2, label: "Lethargic"),
        .init(score: 3, label: "Comatose")
    ]),
    ScoreSign(id: "fits", title: "Fits", options: [
        .init(score: 0, label: "None"),
        .init(score: 1, label: "Infrequent (< 3/day)"),
        .init(score: 2, label: "Frequent (> 2/day)")
    ]),
    ScoreSign(id: "posture", title: "Posture", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Fisting, cycling"),
        .init(score: 2, label: "Strong distal flexion"),
        .init(score: 3, label: "Decerebrate")
    ]),
    ScoreSign(id: "moro", title: "Moro reflex", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Partial"),
        .init(score: 2, label: "Absent")
    ]),
    ScoreSign(id: "grasp", title: "Grasp reflex", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Poor"),
        .init(score: 2, label: "Absent")
    ]),
    ScoreSign(id: "suck", title: "Suck", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Poor"),
        .init(score: 2, label: "Absent ± bites")
    ]),
    ScoreSign(id: "resp", title: "Respiration", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Hyperventilation"),
        .init(score: 2, label: "Brief apnoea"),
        .init(score: 3, label: "IPPV (apnoeic)")
    ]),
    ScoreSign(id: "fontanelle", title: "Anterior fontanelle", options: [
        .init(score: 0, label: "Normal"),
        .init(score: 1, label: "Full, not tense"),
        .init(score: 2, label: "Tense")
    ])
]

// MARK: - Model

final class ThompsonScoreModel: SignScoreModel {
    static let maxTotal: Int = thompsonSigns.reduce(0) { $0 + $1.maxScore }   // 22

    var signCount: Int { thompsonSigns.count }
    var scoredCount: Int { countScored(of: thompsonSigns) }
    var isComplete: Bool { scoredCount == signCount }
    var total: Int { sumScores(of: thompsonSigns) }

    /// Bands: 0 normal · 1–10 mild · 11–14 moderate · 15–22 severe.
    var band: (label: String, color: Color) {
        switch total {
        case 0:       return ("No signs", AppTheme.success)
        case 1...10:  return ("Mild", AppTheme.success)
        case 11...14: return ("Moderate", AppTheme.warning)
        default:      return ("Severe", AppTheme.danger)
        }
    }
}

// MARK: - Calculator section (used on the Resuscitation tab and in the HIE condition)

struct ThompsonScoreSectionView: View {
    @EnvironmentObject private var model: ThompsonScoreModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryCard

            ForEach(thompsonSigns) { sign in
                signRow(sign)
            }

            if model.scoredCount > 0 {
                Button {
                    withAnimation { model.reset() }
                } label: {
                    Label("Reset Thompson score", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.danger)
                }
                .padding(.top, 2)
            }

            notes
        }
    }

    // MARK: Summary

    private var summaryCard: some View {
        let band = model.band
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.isComplete ? "Total Score" : "Provisional Score")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(model.total)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(model.scoredCount == 0 ? AppTheme.textSecondary : band.color)
                    Text("/ \(ThompsonScoreModel.maxTotal)")
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                if model.scoredCount > 0 {
                    PillBadge(text: band.label, color: band.color)
                }
                Text("\(model.scoredCount)/\(model.signCount) signs scored")
                    .font(.caption.bold())
                    .foregroundColor(model.isComplete ? AppTheme.success : AppTheme.warning)
            }
        }
        .padding(14)
        .background((model.scoredCount == 0 ? AppTheme.accent : band.color).opacity(0.07))
        .cornerRadius(14)
    }

    // MARK: One sign

    private func signRow(_ sign: ScoreSign) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sign.title)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 6)],
                      alignment: .leading, spacing: 6) {
                ForEach(sign.options) { option in
                    ScoreChip(
                        option: option,
                        signTitle: sign.title,
                        isSelected: model.selected[sign.id] == option.score
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            model.select(sign: sign.id, score: option.score)
                        }
                    }
                }
            }
        }
    }

    // MARK: Footnotes (bullets, not paragraphs)

    private var notes: some View {
        VStack(alignment: .leading, spacing: 4) {
            noteRow("Bands: 1–10 mild · 11–14 moderate · 15–22 severe")
            noteRow("Repeat serially — trend matters more than one score")
            noteRow("Sedation / anticonvulsants can mask signs")
            noteRow("Confirm cut-offs against your unit protocol")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.warning.opacity(0.07))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.warning.opacity(0.2), lineWidth: 1))
    }

    private func noteRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("•").foregroundColor(AppTheme.warning)
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}
