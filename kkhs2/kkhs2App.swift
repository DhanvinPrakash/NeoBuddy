//
//  kkhs2App.swift
//  kkhs2
//
//  Created by dhanvin_macbook on 3/5/26.
//
//  Firebase is configured here, once, before any view is built. This
//  assumes GoogleService-Info.plist is already added to the Xcode
//  project target (Target Membership checked) — FirebaseApp.configure()
//  reads it automatically at runtime, nothing else to wire up for that.
//

import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct kkhs2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // Single shared instances for the whole app lifetime. Every screen that
    // owns patient inputs or a checklist publishes into the context store,
    // and the floating copilot (mounted once in ContentView) reads from it.
    @StateObject private var copilotContextStore = CopilotContextStore()
    @StateObject private var authManager = AuthManager()
    // Cloud sync for team-added conditions (Supabase).
    @StateObject private var conditionSyncService = ConditionSyncService()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(copilotContextStore)
                .environmentObject(authManager)
                .environmentObject(conditionSyncService)
        }
    }
}
