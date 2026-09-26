import SwiftUI

// MARK: - APGAR Picker Component
struct APGARPickerRow: View {
    let title: String
    @Binding var selection: Int
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)
            Picker("", selection: $selection) {
                ForEach(options.indices, id: \.self) { i in
                    Text("\(i): \(options[i])").tag(i)
                }
            }
            .pickerStyle(.palette)
            .tint(AppTheme.accent)
        }
    }
}

// MARK: - APGAR Info Sheet
struct APGARInfoSheet: View {
    @Environment(\.dismiss) var dismiss

    private let criteria: [(String, String, String, String)] = [
        ("Appearance",   "Blue/pale all over",       "Pink body, blue extremities", "Pink all over"),
        ("Pulse",        "Absent",                   "< 100 bpm",                  "≥ 100 bpm"),
        ("Grimace",      "No response",              "Grimace only",                "Cry / cough / sneeze"),
        ("Activity",     "Limp",                     "Some flexion",                "Active motion"),
        ("Respiration",  "Absent",                   "Slow / irregular",            "Good, strong cry")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("The APGAR score is assessed at 1 and 5 minutes after birth. If the score is < 7 at 5 minutes, reassess every 5 minutes up to 20 minutes.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    // Scoring legend
                    VStack(spacing: 10) {
                        HStack {
                            Text("Score").bold().frame(width: 55, alignment: .leading)
                            Text("Interpretation").bold()
                            Spacer()
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 12)

                        ForEach([
                            ("7 – 10", "Normal", AppTheme.success),
                            ("4 – 6",  "Moderate concern — may need intervention", AppTheme.warning),
                            ("0 – 3",  "Requires immediate resuscitation", AppTheme.danger)
                        ], id: \.0) { score, label, color in
                            HStack(alignment: .top, spacing: 12) {
                                Text(score)
                                    .font(.subheadline.bold())
                                    .foregroundColor(color)
                                    .frame(width: 55, alignment: .leading)
                                Text(label)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                            }
                            .padding(12)
                            .background(color.opacity(0.08))
                            .cornerRadius(10)
                        }
                    }

                    // Criteria table
                    Text("Scoring Criteria")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    VStack(spacing: 8) {
                        HStack {
                            Text("Criterion").bold().frame(maxWidth: .infinity, alignment: .leading)
                            Text("0").bold().frame(width: 80, alignment: .center)
                            Text("1").bold().frame(width: 80, alignment: .center)
                            Text("2").bold().frame(width: 80, alignment: .center)
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)

                        ForEach(criteria, id: \.0) { row in
                            HStack(alignment: .top) {
                                Text(row.0).font(.caption.bold()).frame(maxWidth: .infinity, alignment: .leading)
                                Text(row.1).font(.caption).frame(width: 80, alignment: .center).foregroundColor(AppTheme.danger)
                                Text(row.2).font(.caption).frame(width: 80, alignment: .center).foregroundColor(AppTheme.warning)
                                Text(row.3).font(.caption).frame(width: 80, alignment: .center).foregroundColor(AppTheme.success)
                            }
                            .padding(10)
                            .background(AppTheme.surface)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("APGAR Score")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - APGAR Calculator Section View
struct APGARSectionView: View {
    @Binding var appearance: Int
    @Binding var pulse: Int
    @Binding var grimace: Int
    @Binding var activity: Int
    @Binding var respiration: Int
    @State private var showInfo = false

    var total: Int { appearance + pulse + grimace + activity + respiration }

    var interpretation: (label: String, color: Color) {
        switch total {
        case 7...10: return ("Normal", AppTheme.success)
        case 4...6:  return ("Moderate concern", AppTheme.warning)
        default:     return ("Requires immediate attention", AppTheme.danger)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Score display
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Score")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text("\(total)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(interpretation.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    PillBadge(text: interpretation.label, color: interpretation.color)
                    Button {
                        showInfo = true
                    } label: {
                        Label("Reference", systemImage: "info.circle.fill")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accent)
                    }
                    .sheet(isPresented: $showInfo) {
                        APGARInfoSheet()
                    }
                }
            }
            .padding(14)
            .background(interpretation.color.opacity(0.07))
            .cornerRadius(14)

            Divider().background(AppTheme.accentMuted.opacity(0.3))

            // Pickers
            APGARPickerRow(title: "Appearance (Colour)", selection: $appearance,
                           options: ["Blue/pale all over", "Pink body, blue extremities", "Pink all over"])
            APGARPickerRow(title: "Pulse (Heart Rate)", selection: $pulse,
                           options: ["Absent", "< 100 bpm", "≥ 100 bpm"])
            APGARPickerRow(title: "Grimace (Reflex)", selection: $grimace,
                           options: ["No response", "Grimace only", "Cry / cough / sneeze"])
            APGARPickerRow(title: "Activity (Muscle Tone)", selection: $activity,
                           options: ["Limp", "Some flexion", "Active motion"])
            APGARPickerRow(title: "Respiration", selection: $respiration,
                           options: ["Absent", "Slow / irregular", "Good, strong cry"])

            // Reset
            Button {
                withAnimation {
                    appearance = 0; pulse = 0
                    grimace = 0; activity = 0; respiration = 0
                }
            } label: {
                Label("Reset APGAR", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.danger)
            }
            .padding(.top, 2)
        }
    }
}
