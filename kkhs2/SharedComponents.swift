import SwiftUI
import UIKit

// MARK: - Haptics
/// One tiny facade so every interactive control in the app produces the
/// same consistent, subtle tap feedback. Call from button actions — not
/// from view builders.
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    /// Tick for toggling a single checklist item on/off.
    static func checklistTap() { light.impactOccurred() }

    /// Slightly firmer tick for destructive/primary actions like reset or delete.
    static func mediumTap() { medium.impactOccurred() }

    /// Strong tick for major events (e.g. ECMO activation flows).
    static func heavyTap() { heavy.impactOccurred() }

    /// Success/warning/error style — use when an action completes a group.
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notification.notificationOccurred(type)
    }
}

// MARK: - Collapsible Section
struct CollapsibleSection<Content: View>: View {
    let title: String
    let systemImage: String
    let accentColor: Color
    @Binding var isExpanded: Bool
    let content: () -> Content

    init(
        title: String,
        systemImage: String,
        accentColor: Color = AppTheme.accent,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accentColor = accentColor
        self._isExpanded = isExpanded
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(6)
                        .background(AppTheme.accentMuted.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .background(AppTheme.accentMuted.opacity(0.5))
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.surfaceElevated)
        .cornerRadius(18)
        .shadow(color: AppTheme.accent.opacity(0.08), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppTheme.accentMuted.opacity(0.45), lineWidth: 1)
        )
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    var valueColor: Color = AppTheme.accent

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppTheme.background.opacity(0.6))
        .cornerRadius(10)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let systemImage: String
    var color: Color = AppTheme.accent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

// MARK: - Pill Badge
struct PillBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(20)
            .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Drug Card
struct DrugCard: View {
    let name: String
    let color: Color
    let rows: [(label: String, value: String, sub: String)]
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 9, height: 9)
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
            }

            ForEach(rows, id: \.label) { row in
                HStack {
                    Text(row.label)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(row.value)
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        if !row.sub.isEmpty {
                            Text(row.sub)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(color.opacity(0.07))
                .cornerRadius(9)
            }

            if !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(color.opacity(0.04))
        .cornerRadius(13)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Equipment Row
struct EquipRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.accent)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(AppTheme.background.opacity(0.7))
        .cornerRadius(9)
    }
}
