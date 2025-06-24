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
            // Create model container with proper configuration
            let schema = Schema([
                RegisteredFace.self,
                Employee.self,
                AttendanceRecord.self,
                AttendanceSettings.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ ModelContainer initialized successfully")
            
        } catch {
            print("❌ Failed to initialize ModelContainer: \(error)")
            
            // Fallback: try with minimal models first
            do {
                modelContainer = try ModelContainer(for: RegisteredFace.self)
                print("⚠️ Using fallback ModelContainer with RegisteredFace only")
            } catch {
                fatalError("Failed to initialize even fallback ModelContainer: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .modelContainer(modelContainer)
        }
    }
}
