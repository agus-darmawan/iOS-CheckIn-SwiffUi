//
//  ContentView.swift
//  CheckIn
//
//  Created by Darmawan on 20/06/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedTab: MainTab? = nil
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    MainTabView(handleSelection: handleTabSelection)
                    Spacer()
                    
                    // Footer with custom text
                    HStack {
                        Spacer()
                        Text("Your trusted attendance solution - CheckIn App")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding()
                }
                .navigationDestination(item: $selectedTab, destination: destinationForTab)
            }
        }
        .onAppear {
            SettingsInitializer.createDefaultSettings(modelContext: modelContext)
        }
    }

    private func handleTabSelection(_ tab: MainTab) {
        let requiresAuth = tab == .enroll || tab == .persons || tab == .developerTools || tab == .settings
        
        if requiresAuth && !auth.isAuthenticated {
            auth.authenticate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if auth.isAuthenticated {
                    selectedTab = tab
                }
            }
        } else {
            selectedTab = tab
        }
    }

    @ViewBuilder
    private func destinationForTab(_ tab: MainTab) -> some View {
        switch tab {
        case .attendance: AttendanceView()
        case .enroll: FaceRegistrationView()
        case .capture: LiveFaceRecognitionView(modelContext: modelContext)
                .ignoresSafeArea()
        case .persons: FaceManagementView()
        case .settings: SettingsView()
        case .developerTools:TestView()
        }
    }
}
