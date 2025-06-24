//
//  CheckInApp.swift
//  CheckIn
//
//  Created by Darmawan on 20/06/25.
//

import SwiftUI
import SwiftData

@main
struct CheckInApp: App {
    let modelContainer: ModelContainer
    @StateObject private var auth = AuthViewModel.shared
    
    init() {
        do {
            modelContainer = try ModelContainer(for: RegisteredFace.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .modelContainer(for: [RegisteredFace.self])

        }
    }
}
