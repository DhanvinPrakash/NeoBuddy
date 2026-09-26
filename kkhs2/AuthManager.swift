//
//  AuthManager.swift
//  kkhs2
//
//  Thin wrapper around FirebaseAuth. This is the single source of truth
//  for "is someone signed in" — AuthGateView reads `isAuthenticated` to
//  decide whether to show AuthView or the app itself.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isBusy = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Keeps `user`/`isAuthenticated` in sync with Firebase's own state,
        // including automatic sign-in restoration on app relaunch.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.user = user
            self.isAuthenticated = user != nil
        }
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    var displayEmail: String { user?.email ?? "" }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    func signUp(email: String, password: String) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    func sendPasswordReset(email: String) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            errorMessage = "Password reset email sent to \(email)."
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    /// Maps FirebaseAuth's error codes to short, non-technical copy.
    private static func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .invalidEmail:            return "That email address doesn't look right."
        case .emailAlreadyInUse:       return "An account already exists for that email."
        case .weakPassword:            return "Password must be at least 6 characters."
        case .wrongPassword, .userNotFound, .invalidCredential:
                                        return "Incorrect email or password."
        case .networkError:            return "No network connection. Check your connection and try again."
        case .tooManyRequests:         return "Too many attempts. Please wait a moment and try again."
        default:                       return error.localizedDescription
        }
    }
}
