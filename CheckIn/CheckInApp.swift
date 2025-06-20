//
//  CheckInApp.swift
//  CheckIn
//
//  Created by Darmawan on 20/06/25.
//

import SwiftUI

@main
struct CheckInApp: App {
    @StateObject private var auth = AuthViewModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth) // ✅ Inject here
        }
    }
}
