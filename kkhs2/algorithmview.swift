import SwiftUI

// MARK: - Timeline Node Model
// A single ordered list drives the whole flowchart so the connecting rail
// can be drawn once, continuously, behind every node — rather than as
// separate arrow glyphs stitched between independent cards.
//
// Updated to the Singapore Neonatal Resuscitation Guidelines 2026
// (Kong et al., Singapore Medical Journal 2026;67(7):453–465).
// Changes vs the 2021 flow:
//   • "Liquor clear?" removed from the initial assessment questions
//   • Umbilical cord management plan added before the initial steps
//   • Cap added for thermoregulation in the initial steps
//   • T-piece resuscitator preferred; PEEP 5–6 cmH₂O
//   • < 33 wk starts on ≥ 30% oxygen (was 21–30%)
//   • Reassess respiratory status once HR > 100/min
//   • ECG preferred for continuous HR during ongoing resuscitation
//   • Intraosseous access added alongside UVC
//   • SGA device ≥ 34 wk / > 1500 g alternative
//   • Chest compressions can be run from the head of the bed; 3:1 kept
//   • IO added for adrenaline; sodium bicarbonate removed (no longer
//     recommended in prolonged resuscitation)
//   • Consider equipment failure if poor response to resuscitation
//   • < 24 wk management individualised with parents (no blanket < 23 wk rule)

private enum AlgoNodeKind {
    case step(icon: String, color: Color, title: String, bullets: [String])
    case decision(question: String, yes: String, no: String)
}

private struct AlgoNode {
    let kind: AlgoNodeKind
}

private let algorithmNodes: [AlgoNode] = [
    .init(kind: .step(icon: "checklist", color: AppTheme.teal,
        title: "Before Birth",
        bullets: [
            "Antenatal counselling",
            "Team briefing — review risks, check equipment, allocate roles",
            "Agree the umbilical cord management plan with the obstetric team"
        ])),

    .init(kind: .step(icon: "clock.badge.checkmark", color: AppTheme.purple,
        title: "Umbilical Cord Management",
        bullets: [
            "Vigorous newborn (any gestation) — delayed cord clamping ≥ 60 s",
            "Non-vigorous ≥ 35 wk — intact cord milking may be considered",
            "Cord milking NOT recommended < 28 wk (severe IVH risk)",
            "Special situations (twins, anomalies, placental problems) — individualise"
        ])),

    .init(kind: .decision(
        question: "Term gestation? Good tone? Breathing or crying?",
        yes: "Routine care — dry, warm, maintain airway, skin-to-skin, ongoing evaluation",
        no: "Proceed to Initial Steps")),

    .init(kind: .step(icon: "thermometer.medium", color: AppTheme.warning,
        title: "Initial Steps",
        bullets: [
            "Golden Minute — complete within first 60 s",
            "Warm & dry — cap for thermoregulation (especially < 33 wk)",
            "Polyethylene wrap under radiant warmer if < 33 wk (place without drying)",
            "Stimulate — gently rub soles of feet or back (during DCC)",
            "Position airway — supine, neutral sniffing position",
            "Suction only if airway visibly obstructed (80–100 mmHg, < 10 s)",
            "By the end of the golden minute, assess breathing & HR"
        ])),

    .init(kind: .decision(
        question: "Apnoeic, gasping, or HR < 100/min after initial steps?",
        yes: "Start Positive Pressure Ventilation",
        no: "If laboured breathing or persistent cyanosis → SpO₂ monitoring, O₂, consider CPAP (PEEP 5–6 cmH₂O)")),

    .init(kind: .step(icon: "lungs.fill", color: AppTheme.accent,
        title: "Positive Pressure Ventilation (PPV)",
        bullets: [
            "Initiate within 60 s of birth — T-piece resuscitator preferred (self-inflating bag as backup)",
            "≥ 33 wk: start at 21% O₂  ·  < 33 wk: start ≥ 30% O₂",
            "Rate 30–60 breaths/min, inspiratory time ≤ 1 s",
            "Inspiratory pressure 20–25 cm H₂O, titrate to chest rise",
            "PEEP 5–6 cm H₂O recommended, especially in preterm",
            "Apply SpO₂ probe to right hand (preductal)",
            "ECG preferred for continuous HR during ongoing resuscitation"
        ])),

    .init(kind: .step(icon: "gauge.open.with.lines.needle.33percent", color: AppTheme.teal,
        title: "Target Preductal SpO₂",
        bullets: [
            "1 min — 60–65%",
            "2 min — 65–70%",
            "3 min — 70–75%",
            "4 min — 75–80%",
            "5 min — 80–85%  ·  avoid SpO₂ < 80% and/or bradycardia at 5 min",
            "10 min — 85–95%"
        ])),

    .init(kind: .decision(
        question: "HR < 100/min after 1 min of PPV?",
        yes: "Ventilation corrective steps (DOPE) — consider ETT or SGA (≥ 34 wk / > 1500 g)",
        no: "Continue PPV, titrate O₂ to SpO₂ targets")),

    .init(kind: .decision(
        question: "HR > 100/min now — respiratory status?",
        yes: "Reassess breathing & respiratory status after HR stabilises",
        no: "Continue PPV and corrective steps")),

    .init(kind: .decision(
        question: "HR < 60/min despite effective ventilation (≥ 30 s)?",
        yes: "Start chest compressions",
        no: "Continue PPV")),

    .init(kind: .step(icon: "hand.raised.fill", color: AppTheme.danger,
        title: "Chest Compressions",
        bullets: [
            "Two-thumb encircling-hands technique, lower third of sternum",
            "Depress ⅓ of anteroposterior chest diameter, allow full recoil",
            "Coordinated 3:1 ratio — 90 compressions + 30 inflations (120 events/min)",
            "Keep 3:1 coordination even after the airway is secured",
            "Ventilate via ETT or SGA during compressions",
            "Increase O₂ to 100%, then titrate to SpO₂ targets",
            "Can be administered from the head of the bed once the airway is secured",
            "Reassess HR, SpO₂ & breathing every 60 s"
        ])),

    .init(kind: .decision(
        question: "HR < 60/min after 60 s of coordinated CPR?",
        yes: "Check airway & compressions, then administer IV/IO Adrenaline",
        no: "Continue CPR, reassess every 60 s")),

    .init(kind: .step(icon: "pills.fill", color: AppTheme.purple,
        title: "Medications",
        bullets: [
            "IV/IO Adrenaline 1:10,000 → 0.1–0.3 mL/kg rapid bolus + 3 mL saline flush",
            "Repeat every 3–5 min if HR remains < 60/min",
            "If no IV/IO: ET adrenaline 0.5–1.0 mL/kg (obtain IV/IO access as soon as possible)",
            "UVC remains standard access; intraosseous (IO) if UV access not feasible",
            "Early volume expansion 10 mL/kg 0.9% saline if poor response or hypovolaemia suspected",
            "O Rh-negative uncrossmatched blood if blood loss suspected",
            "Sodium bicarbonate is NO LONGER recommended in prolonged resuscitation",
            "Poor response to all interventions → consider equipment failure"
        ])),

    .init(kind: .step(icon: "xmark.circle.fill", color: AppTheme.textSecondary,
        title: "Withholding & Discontinuing Resuscitation",
        bullets: [
            "No HR after 20 min of optimum resuscitation + correction of reversible causes → may discontinue",
            "< 24 wk — individualise; shared decision with neonatal, obstetric teams & parents",
            "Maximal resuscitation until parents have been consulted",
            "Decision must be individualised and discussed with parents"
        ])),

    .init(kind: .step(icon: "checkmark.seal.fill", color: AppTheme.success,
        title: "Post-Resuscitation Care",
        bullets: [
            "Record and maintain temperature 36.5–37.5°C — avoid hypothermia & hyperthermia",
            "Monitor glucose early & regularly — avoid hypo/hyperglycaemia and wide swings",
            "Therapeutic hypothermia if ≥ 36 wk with moderate–severe HIE (within 6 h, 33–34°C for 72 h)",
            "Update parents",
            "Team debriefing"
        ])),
]

// MARK: - Full Algorithm View
struct ResuscitationAlgorithmView: View {
    private let railWidth: CGFloat = 34

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Source line
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "doc.text.fill")
                    .font(.caption2)
                Text("SNRC 2026 · Newborn Resuscitation Algorithm")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(AppTheme.textSecondary)
            .padding(.bottom, AppTheme.Spacing.md)

            ForEach(Array(algorithmNodes.enumerated()), id: \.offset) { index, node in
                AlgoTimelineRow(
                    node: node,
                    isFirst: index == 0,
                    isLast: index == algorithmNodes.count - 1,
                    stepNumber: stepNumber(upTo: index),
                    railWidth: railWidth
                )
            }
        }
    }

    /// Counts only .step nodes for the visible numbering — decisions get a
    /// diamond marker instead of a number, so numbering should skip them.
    private func stepNumber(upTo: Int) -> Int {
        algorithmNodes[0...upTo].reduce(0) { count, node in
            if case .step = node.kind { return count + 1 }
            return count
        }
    }
}

// MARK: - One row: rail marker + connecting line + content card
private struct AlgoTimelineRow: View {
    let node: AlgoNode
    let isFirst: Bool
    let isLast: Bool
    let stepNumber: Int
    let railWidth: CGFloat

    private var markerColor: Color {
        switch node.kind {
        case .step(_, let color, _, _): return color
        case .decision: return .indigo
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            // Rail: continuous line with a marker centered on this row.
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : AppTheme.accentMuted.opacity(0.6))
                    .frame(width: 2)
                    .frame(minHeight: AppTheme.Spacing.md)

                marker

                Rectangle()
                    .fill(isLast ? Color.clear : AppTheme.accentMuted.opacity(0.6))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: railWidth)

            // Content
            content
                .padding(.bottom, AppTheme.Spacing.lg)
        }
    }

    @ViewBuilder
    private var marker: some View {
        switch node.kind {
        case .step:
            ZStack {
                Circle().fill(markerColor)
                Text("\(stepNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }
            .frame(width: railWidth, height: railWidth)

        case .decision:
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(markerColor)
                    .frame(width: railWidth - 6, height: railWidth - 6)
                    .rotationEffect(.degrees(45))
                Image(systemName: "questionmark")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
            }
            .frame(width: railWidth, height: railWidth)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch node.kind {
        case .step(let icon, let color, let title, let bullets):
            AlgoStepCard(icon: icon, color: color, title: title, bullets: bullets)
        case .decision(let question, let yes, let no):
            AlgoDecisionCard(question: question, yes: yes, no: no)
        }
    }
}

// MARK: - Step card
private struct AlgoStepCard: View {
    let icon: String
    let color: Color
    let title: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(AppTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs + 2) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                        Circle()
                            .fill(color.opacity(0.7))
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)
                        Text(bullet)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous).stroke(color.opacity(0.22), lineWidth: 1))
    }
}

// MARK: - Decision card
private struct AlgoDecisionCard: View {
    let question: String
    let yes: String
    let no: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(question)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.indigo)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: AppTheme.Spacing.xs) {
                branchRow(label: "YES", text: yes, color: AppTheme.success)
                branchRow(label: "NO", text: no, color: AppTheme.warning)
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.indigo.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous).stroke(Color.indigo.opacity(0.22), lineWidth: 1))
    }

    private func branchRow(label: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text(label)
                .font(.caption2.weight(.heavy))
                .foregroundColor(color)
                .frame(width: 34, alignment: .leading)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
