//
//  KeyboardObserver.swift
//  kkhs2
//
//  Created by dhanvin_macbook on 24/9/26.
//


//
//  KeyboardTools.swift
//  kkhs2
//
//  Fixes the "numeric keypad won't go away" bug on iOS.
//
//  Root cause: the old `ToolbarItemGroup(placement: .keyboard)` was attached to
//  the root TabView. Keyboard toolbar items only render when there is a
//  navigation container around the focused field, and the Resuscitation and
//  Infusions tabs have none — so "Done" never appeared, and decimalPad /
//  numberPad have no return key.
//
//  This file adds a floating "Done" bar that tracks the keyboard frame directly,
//  so it works on every tab, inside collapsible sections, and over the copilot.
//

import SwiftUI
import UIKit
import Combine

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

final class KeyboardObserver: ObservableObject {
    @Published private(set) var height: CGFloat = 0
    private var bag = Set<AnyCancellable>()

    init() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .sink { [weak self] note in
                guard let end = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                let screenHeight = (note.object as? UIScreen)?.bounds.height ?? end.maxY
                self?.height = max(0, screenHeight - end.minY)
            }
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.height = 0 }
            .store(in: &bag)
    }
}

struct KeyboardDoneBar: View {
    @StateObject private var keyboard = KeyboardObserver()

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            if keyboard.height > 0 {
                HStack {
                    Spacer()
                    Button {
                        Haptics.checklistTap()
                        dismissKeyboard()
                    } label: {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .foregroundColor(AppTheme.accent)
                    .accessibilityLabel("Dismiss keyboard")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) { Divider() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, keyboard.height)
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.2), value: keyboard.height)
    }
}

extension View {
    /// Floating "Done" bar pinned above the keyboard. Mount once at the root.
    func keyboardDoneBar() -> some View {
        overlay(KeyboardDoneBar())
    }
}