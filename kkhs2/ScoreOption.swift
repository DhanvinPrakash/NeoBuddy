//
//  ScoreOption.swift
//  kkhs2
//
//  Created by dhanvin_macbook on 25/9/26.
//


//
//  ScoreEngine.swift
//  kkhs2
//
//  Shared engine behind every "answer N discrete bedside signs, sum the
//  scores" calculator (Thompson HIE score, Ballard gestational-age score).
//  Both previously reimplemented the same selection dictionary, toggle
//  logic, and chip button from scratch, with only cosmetic differences.
//  This file is that logic written once — nothing about how Thompson or
//  Ballard look or behave changes, only where the shared code lives.
//

import SwiftUI
import Combine

/// One selectable option for a sign, e.g. "2: Lethargic".
struct ScoreOption: Identifiable {
    let score: Int
    let label: String
    var id: Int { score }
}

/// One scored bedside sign, e.g. "Tone", with its options.
struct ScoreSign: Identifiable {
    let id: String
    let title: String
    let options: [ScoreOption]
    var maxScore: Int { options.map(\.score).max() ?? 0 }
}

/// Base class for "pick one option per sign, sum the scores" calculators.
/// A sign with no entry in `selected` is "not yet assessed" — distinct from
/// scoring zero — so callers can tell a provisional total from a complete one.
class SignScoreModel: ObservableObject {
    @Published var selected: [String: Int] = [:]

    /// Tapping the already-selected option again clears it back to unassessed.
    func select(sign: String, score: Int) {
        if selected[sign] == score {
            selected.removeValue(forKey: sign)
        } else {
            selected[sign] = score
        }
    }

    func reset() { selected = [:] }

    func countScored(of signs: [ScoreSign]) -> Int {
        signs.filter { selected[$0.id] != nil }.count
    }

    func sumScores(of signs: [ScoreSign]) -> Int {
        signs.reduce(0) { $0 + (selected[$1.id] ?? 0) }
    }
}

/// One tappable "score: label" chip, shared by every sign-based calculator.
/// `layout` reproduces the two arrangements the app already used:
///   .leadingNumber — Thompson's grid chips, number flush against the label
///   .gutterNumber  — Ballard's stacked chips, number right-aligned in a
///                    fixed gutter so scores line up down the column
/// The chip's content, colors, and accessibility are identical either way;
/// only the number's placement differs.
struct ScoreChip: View {
    enum Layout { case leadingNumber, gutterNumber }

    let option: ScoreOption
    let signTitle: String
    let isSelected: Bool
    var layout: Layout = .leadingNumber
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.09))
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(signTitle): \(option.label), \(option.score) points")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var content: some View {
        switch layout {
        case .leadingNumber:
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(option.score)").font(.caption.weight(.heavy))
                label
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .gutterNumber:
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(option.score)")
                    .font(.caption.weight(.heavy))
                    .frame(width: 18, alignment: .trailing)
                label
                Spacer(minLength: 0)
            }
        }
    }

    private var label: some View {
        Text(option.label)
            .font(.caption)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
