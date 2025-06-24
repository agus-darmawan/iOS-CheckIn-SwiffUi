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
    @State private var attendanceViewModel = AttendanceViewModel()
    @StateObject private var auth = AuthViewModel.shared
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Person.self, CheckInLog.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(attendanceViewModel)
                .environmentObject(auth)
                .modelContainer(modelContainer)
                .onAppear {
                    attendanceViewModel.setModelContext(modelContainer.mainContext)
                }
        }
    }
}
