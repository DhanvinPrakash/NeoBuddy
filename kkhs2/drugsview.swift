import SwiftUI

// MARK: - Drug Dose Calculator
struct DrugDoses {
    let weightKg: Double

    var epiIVLow:   Double { weightKg * 0.1 }
    var epiIVHigh:  Double { weightKg * 0.3 }
    var epiETLow:   Double { weightKg * 0.5 }
    var epiETHigh:  Double { weightKg * 1.0 }
    var fluidBolus: Double { weightKg * 10 }
    var dextrose10: Double { weightKg * 2.5 }

    func fmt(_ v: Double, decimals: Int = 2) -> String {
        String(format: "%.\(decimals)f", v)
    }
}

// MARK: - Drugs Section View
struct DrugsSectionView: View {
    let weightKg: Double

    var body: some View {
        if weightKg > 0 {
            let d = DrugDoses(weightKg: weightKg)
            VStack(alignment: .leading, spacing: 14) {

                HStack(spacing: 6) {
                    Image(systemName: "scalemass.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("Calculated for \(d.fmt(weightKg)) kg")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                DrugCard(
                    name: "Adrenaline (Epinephrine) 1:10,000 — 0.1 mg/mL",
                    color: AppTheme.danger,
                    rows: [
                        (label: "IV / UVC dose",    value: "\(d.fmt(d.epiIVLow)) – \(d.fmt(d.epiIVHigh)) mL", sub: "0.1 – 0.3 mL/kg"),
                        (label: "ET dose",           value: "\(d.fmt(d.epiETLow)) – \(d.fmt(d.epiETHigh)) mL", sub: "0.5 – 1.0 mL/kg"),
                        (label: "Saline flush (IV)", value: "3 mL",                                              sub: "always follow IV dose")
                    ],
                    note: "Give IV adrenaline if HR < 60/min after 60 s CPR. Repeat every 3–5 min. Prefer IV/UVC route; use ET only if IV unavailable."
                )

                DrugCard(
                    name: "Volume Replacement — 0.9% Normal Saline",
                    color: AppTheme.accent,
                    rows: [
                        (label: "10 mL/kg bolus", value: "\(d.fmt(d.fluidBolus, decimals: 1)) mL", sub: "over 5 – 10 min via IV/UVC")
                    ],
                    note: "For suspected hypovolaemia unresponsive to resuscitation. Use uncross-matched O, Rh-negative blood if haemorrhage suspected."
                )

                DrugCard(
                    name: "Dextrose 10% (post-resuscitation hypoglycaemia)",
                    color: AppTheme.warning,
                    rows: [
                        (label: "2.5 mL/kg IV", value: "\(d.fmt(d.dextrose10, decimals: 1)) mL", sub: "if glucose < 2.6 mmol/L")
                    ],
                    note: "Monitor blood glucose after resuscitation at appropriate intervals. Avoid hypo- and hyperglycaemia and wide fluctuations."
                )

                // Reminder footer
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.warning)
                        .font(.caption)
                    Text("Always double-check doses before administration. See the Infusions section for dilution & rate calculators.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(10)
                .background(AppTheme.warning.opacity(0.07))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.warning.opacity(0.2), lineWidth: 1))
            }
        } else {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(AppTheme.accentLight)
                Text("Enter patient weight to calculate drug doses.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .italic()
            }
        }
    }
}

