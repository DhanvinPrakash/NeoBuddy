//
//  AIProtocolCopilotView.swift
//  kkhs2
//
//  A floating, draggable panel — not a chat screen. It sits above whichever
//  tab is active, is opened/closed with a single tap, and its content is a
//  compact structured readout (primary action, warnings, checklist gaps),
//  never a scrolling conversation.
//

import SwiftUI

struct CopilotFloatingLayer: View {
    @EnvironmentObject private var contextStore: CopilotContextStore
    @StateObject private var router = CopilotRouter()

    @State private var isExpanded = false
    @State private var mode: CopilotMode = .nextStep
    @State private var query: String = ""
    @State private var response: CopilotResponse?
    @State private var isLoading = false
    @State private var showSettings = false

    @State private var panelOffset: CGSize = .zero
    @State private var dragTranslation: CGSize = .zero

    private let panelWidth: CGFloat = 340
    private let panelHeight: CGFloat = 460
    private let trailingPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 90
    private let edgeInset: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                Color.clear // keeps the GeometryReader from affecting layout of siblings

                if isExpanded {
                    panel
                        .frame(width: min(panelWidth, geo.size.width - 24))
                        .offset(x: panelOffset.width + dragTranslation.width,
                                y: panelOffset.height + dragTranslation.height)
                        .gesture(dragGesture(in: geo.size))
                        .transition(.scale(scale: 0.92, anchor: .bottomTrailing).combined(with: .opacity))
                        .padding(.trailing, 16)
                        .padding(.bottom, 90)
                        .accessibilityAddTraits(.isModal)
                } else {
                    fab
                        .padding(.trailing, 16)
                        .padding(.bottom, 90)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomTrailing)
        }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { dragTranslation = $0.translation }
            .onEnded { value in
                panelOffset.width += value.translation.width
                panelOffset.height += value.translation.height
                dragTranslation = .zero
                clamp(in: size)
            }
    }

    private func clamp(in size: CGSize) {
        // The panel rests naturally flush against the bottom-trailing corner
        // (via .padding(.trailing/.bottom)), not centered — so bounds must
        // be computed from that resting position, not from screen center.
        let width = min(panelWidth, size.width - 24)
        let naturalRight = size.width - trailingPadding
        let naturalLeft = naturalRight - width
        let naturalBottom = size.height - bottomPadding
        let naturalTop = naturalBottom - panelHeight

        let minX = edgeInset - naturalLeft                       // keep left edge on-screen
        let maxX: CGFloat = 0                                     // don't drift past the flush-right resting edge
        let minY = edgeInset - naturalTop                         // keep top edge below the status bar / safe area
        let maxY = max(0, (size.height - edgeInset) - naturalBottom) // small allowance to drag down toward the tab bar

        panelOffset.width = min(maxX, max(minX, panelOffset.width))
        panelOffset.height = min(maxY, max(minY, panelOffset.height))
    }

    // MARK: - Collapsed button

    private var fab: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { isExpanded = true }
        } label: {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(AppTheme.accent)
                .clipShape(Circle())
                .shadow(color: AppTheme.accent.opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .accessibilityLabel("Open protocol copilot")
        .accessibilityHint("Shows next step, dose checks, and checklist status")
    }

    // MARK: - Expanded panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(AppTheme.accentMuted.opacity(0.4))
            modePicker
            if mode.takesQuery {
                queryField
            }
            runButton
            Divider().background(AppTheme.accentMuted.opacity(0.4))
            ScrollView {
                resultView
                    .padding(12)
            }
            .frame(maxHeight: 260)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentMuted.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
        .sheet(isPresented: $showSettings) { CopilotSettingsView() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg.rectangle.fill")
                .foregroundColor(AppTheme.accent)
            Text("Protocol Copilot")
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("Copilot settings")
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) { isExpanded = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 30, height: 30)
            }
            .accessibilityLabel("Close copilot")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CopilotMode.allCases) { m in
                    Button {
                        mode = m
                        response = nil
                    } label: {
                        Label(m.label, systemImage: m.systemImage)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(mode == m ? AppTheme.accent : AppTheme.accent.opacity(0.09))
                            .foregroundColor(mode == m ? .white : AppTheme.accent)
                            .cornerRadius(20)
                    }
                    .accessibilityLabel("\(m.label) mode")
                    .accessibilityAddTraits(mode == m ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 6)
    }

    private var queryField: some View {
        TextField(mode == .doseCheck ? "e.g. adrenaline" : "topic (optional)", text: $query)
            .font(.subheadline)
            .padding(9)
            .background(AppTheme.surface)
            .cornerRadius(9)
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(AppTheme.accentMuted.opacity(0.6), lineWidth: 1))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
    }

    private var runButton: some View {
        Button { Task { await run() } } label: {
            HStack(spacing: 8) {
                if isLoading { ProgressView().tint(.white) }
                Text(isLoading ? "Checking…" : "Run")
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(AppTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isLoading)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var resultView: some View {
        if let r = response {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ConfidenceBadge(level: r.confidence)
                    Spacer()
                    if !router.lastBackendUsed.isEmpty {
                        Text(router.lastBackendUsed)
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                if !r.primary.isEmpty {
                    Text(r.primary)
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !r.secondary.isEmpty {
                    Text(r.secondary)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ForEach(r.items, id: \.self) { item in
                    Label(item, systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                }
                ForEach(r.warnings, id: \.self) { w in
                    Label(w, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.danger)
                }
                ForEach(r.missing, id: \.self) { m in
                    Label(m, systemImage: "questionmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.warning)
                }

                if !r.reference_ids.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(r.reference_ids, id: \.self) { ref in
                            Text(ref)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accentMuted.opacity(0.3))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        } else if !isLoading {
            Text("Pick a mode and tap Run. The copilot only uses data already entered in this app.")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func run() async {
        isLoading = true
        let payload = ProtocolReferenceBuilder.buildPayload(from: contextStore)
        let result = await router.run(mode: mode, userQuery: query, context: payload)
        response = result
        isLoading = false
    }
}

private struct ConfidenceBadge: View {
    let level: String

    private var color: Color {
        switch level {
        case "high":   return AppTheme.success
        case "medium": return AppTheme.warning
        default:       return AppTheme.danger
        }
    }

    var body: some View {
        Text(level.uppercased())
            .font(.caption2.bold())
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(20)
            .accessibilityLabel("Confidence: \(level)")
    }
}

// MARK: - Settings

struct CopilotSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private var appleIntelligenceStatus: String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AppleIntelligenceBackend.isAvailable
                ? "Available on this device — used automatically, on-device."
                : "Not available on this device (unsupported hardware, region, or Apple Intelligence is off in Settings). Gemini will be used instead."
        }
        #endif
        return "Requires iOS 26 or later. Gemini will be used instead."
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Apple Intelligence") {
                    Text(appleIntelligenceStatus)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Section {
                    HStack(spacing: 8) {
                        Image(systemName: GeminiConfig.isConfigured ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(GeminiConfig.isConfigured ? AppTheme.success : AppTheme.warning)
                        Text(GeminiConfig.isConfigured ? "Configured" : "Not configured")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.textPrimary)
                    }
                } header: {
                    Text("Gemini fallback")
                } footer: {
                    Text("Used only on devices where Apple Intelligence isn't available. The key is set once by the developer at build time in Xcode — there's nothing for you to enter here.")
                }
            }
            .navigationTitle("Copilot Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
