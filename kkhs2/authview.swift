//
//  AuthView.swift
//  kkhs2
//
//  Email/password sign-in, styled to match the rest of the app and to
//  read correctly in both light and dark mode.
//

import SwiftUI

// MARK: - Gate

/// Root switch: shows the sign-in screen until Firebase reports a signed-in
/// user, then shows the app. Mount this once, at the top of the app.
struct AuthGateView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authManager.isAuthenticated)
    }
}

// MARK: - Sign in / Sign up

private enum AuthField: Hashable { case email, password }

struct AuthView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: AuthField?

    private enum Mode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 6 && !authManager.isBusy
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.background, AppTheme.backgroundDeep],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {

                    // ── Brand mark ───────────────────────────────────
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.15))
                                .frame(width: 76, height: 76)
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
                        }
                        Text("Neonatal Resus")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, AppTheme.Spacing.xxl)

                    // ── Mode switch ──────────────────────────────────
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    // ── Fields ───────────────────────────────────────
                    VStack(spacing: AppTheme.Spacing.md) {
                        AuthTextField(
                            label: "Email",
                            systemImage: "envelope.fill",
                            text: $email,
                            isSecure: false
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                        AuthTextField(
                            label: "Password",
                            systemImage: "lock.fill",
                            text: $password,
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submit() }

                        if mode == .signIn {
                            HStack {
                                Spacer()
                                Button("Forgot password?") {
                                    Task { await authManager.sendPasswordReset(email: email) }
                                }
                                .font(.footnote.weight(.medium))
                                .foregroundColor(AppTheme.accent)
                                .disabled(email.isEmpty)
                            }
                        }
                    }
                    .appCard()

                    if let message = authManager.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(AppTheme.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .transition(.opacity)
                    }

                    // ── Submit ───────────────────────────────────────
                    Button(action: submit) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            if authManager.isBusy {
                                ProgressView().tint(.white)
                            }
                            Text(mode == .signIn ? "Sign In" : "Create Account")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canSubmit ? AppTheme.accent : AppTheme.accent.opacity(0.4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))
                    }
                    .disabled(!canSubmit)

                    // ── Privacy disclaimer ───────────────────────────
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        disclaimerRow("lock.shield.fill",
                                      "Your email and password are used only to sign you in.")
                        disclaimerRow("eye.slash.fill",
                                      "No tracking of your activity. Patient values you enter (weight, gestational age, scores, checklists) are not saved or linked to your account.")
                        disclaimerRow("person.crop.circle.badge.exclamationmark",
                                      "Do not enter patient names or identifiers.")
                        disclaimerRow("stethoscope",
                                      "Decision-support aid only — follow your unit protocol and clinical judgement.")
                    }
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous))

                    Spacer(minLength: AppTheme.Spacing.xxl)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
        .onChange(of: mode) { _ in authManager.errorMessage = nil }
    }

    private func disclaimerRow(_ systemImage: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundColor(AppTheme.accent)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func submit() {
        focusedField = nil
        guard canSubmit else { return }
        Task {
            switch mode {
            case .signIn: await authManager.signIn(email: email, password: password)
            case .signUp: await authManager.signUp(email: email, password: password)
            }
        }
    }
}

// MARK: - Reusable labeled field

private struct AuthTextField: View {
    let label: String
    let systemImage: String
    @Binding var text: String
    let isSecure: Bool
    @State private var revealPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: systemImage)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 18)

                Group {
                    if isSecure && !revealPassword {
                        SecureField("Required", text: $text)
                    } else {
                        TextField("Required", text: $text)
                    }
                }
                .foregroundColor(AppTheme.textPrimary)

                if isSecure {
                    Button {
                        revealPassword.toggle()
                    } label: {
                        Image(systemName: revealPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm, style: .continuous)
                    .stroke(AppTheme.accentMuted.opacity(0.6), lineWidth: 1)
            )
        }
    }
}
