//
//  Theme.swift
//  kkhs2
//
//  Design system: dynamic colors that adapt to light/dark mode, plus a
//  shared spacing/radius/typography scale so every screen in the app
//  reads consistently. Light mode is visually unchanged from the
//  original baby-blue palette. Dark mode uses a dark navy background
//  with brightened accents/semantic colors so contrast stays AA-legible.
//

import SwiftUI

// MARK: - Dynamic color helper
private extension Color {
    /// Builds a Color that resolves differently in light vs dark mode.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - App Theme
struct AppTheme {

    // MARK: Backgrounds
    // Light: baby blue (unchanged). Dark: deep navy, not pure black —
    // keeps the same "calm clinical" feel instead of an OLED-black app.
    static let background = Color(
        light: Color(red: 0.88, green: 0.94, blue: 1.0),
        dark:  Color(red: 0.043, green: 0.071, blue: 0.125)   // #0B1220
    )
    static let backgroundDeep = Color(
        light: Color(red: 0.80, green: 0.89, blue: 0.98),
        dark:  Color(red: 0.020, green: 0.039, blue: 0.078)   // #050A14
    )
    static let surface = Color(
        light: Color(red: 0.94, green: 0.97, blue: 1.0),
        dark:  Color(red: 0.078, green: 0.106, blue: 0.169)   // #141B2B
    )
    static let surfaceElevated = Color(
        light: Color.white.opacity(0.75),
        dark:  Color(red: 0.098, green: 0.133, blue: 0.204)   // #192235
    )

    // MARK: Accents
    static let accent = Color(
        light: Color(red: 0.18, green: 0.47, blue: 0.78),
        dark:  Color(red: 0.36, green: 0.65, blue: 0.98)      // brighter for dark bg contrast
    )
    static let accentLight = Color(
        light: Color(red: 0.45, green: 0.70, blue: 0.95),
        dark:  Color(red: 0.55, green: 0.76, blue: 1.0)
    )
    static let accentMuted = Color(
        light: Color(red: 0.67, green: 0.84, blue: 0.97),
        dark:  Color(red: 0.24, green: 0.32, blue: 0.46)      // slate blue border/hairline
    )

    // MARK: Semantic
    static let danger = Color(
        light: Color(red: 0.85, green: 0.25, blue: 0.25),
        dark:  Color(red: 1.00, green: 0.42, blue: 0.42)
    )
    static let warning = Color(
        light: Color(red: 0.95, green: 0.60, blue: 0.10),
        dark:  Color(red: 1.00, green: 0.72, blue: 0.30)
    )
    static let success = Color(
        light: Color(red: 0.18, green: 0.72, blue: 0.45),
        dark:  Color(red: 0.32, green: 0.85, blue: 0.58)
    )
    static let purple = Color(
        light: Color(red: 0.50, green: 0.25, blue: 0.80),
        dark:  Color(red: 0.68, green: 0.52, blue: 0.98)
    )
    static let teal = Color(
        light: Color(red: 0.10, green: 0.65, blue: 0.65),
        dark:  Color(red: 0.30, green: 0.80, blue: 0.80)
    )

    // MARK: Text
    static let textPrimary = Color(
        light: Color(red: 0.10, green: 0.18, blue: 0.30),
        dark:  Color(red: 0.94, green: 0.96, blue: 1.00)
    )
    static let textSecondary = Color(
        light: Color(red: 0.38, green: 0.50, blue: 0.65),
        dark:  Color(red: 0.62, green: 0.70, blue: 0.82)
    )

    // MARK: - Spacing scale (HIG-style 4pt rhythm)
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner radius scale
    struct Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 22
    }

    // MARK: Card style
    static func card() -> some View {
        RoundedRectangle(cornerRadius: Radius.lg)
            .fill(surfaceElevated)
            .shadow(color: .black.opacity(shadowOpacity), radius: 8, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(accentMuted.opacity(0.5), lineWidth: 1)
            )
    }

    /// Shadows read as "muddy boxes" on dark backgrounds, so keep them
    /// faint there and rely on the hairline stroke for separation instead.
    static var shadowOpacity: Double { 0.10 }
}

// MARK: - View Modifiers
extension View {
    /// The single, canonical "raised card" look used everywhere in the
    /// app. Do not additionally wrap this in another .background/.overlay —
    /// stacking card modifiers is what produced the doubled-border "boxes
    /// inside boxes" artifacts.
    func appCard(padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        self
            .padding(padding)
            .background(AppTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg, style: .continuous)
                    .stroke(AppTheme.accentMuted.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(AppTheme.shadowOpacity), radius: 10, x: 0, y: 4)
    }

    /// Back-compat name used throughout the existing views.
    func sectionCard() -> some View {
        appCard()
    }

    /// Dismisses the keyboard from anywhere (used as a background tap
    /// target behind text fields).
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
