//
//  ContentView.swift
//  CheckIn
//
//  Created by Darmawan on 20/06/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedTab: MainTab? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    MainTabView(handleSelection: handleTabSelection)
                    Spacer()
                }
                .navigationDestination(item: $selectedTab, destination: destinationForTab)
            }
        }
    }

    private func handleTabSelection(_ tab: MainTab) {
        let requiresAuth = tab == .enroll || tab == .persons
        
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
        case .enroll: TestView(title: "Enroll", color: .red)
        case .location: LocationView()
        case .capture: TestView(title: "Capture", color: .orange)
        case .attribute: TestView(title: "Attribute", color: .purple)
        case .settings: TestView(title: "Settings", color: .gray)
        case .persons: TestView(title: "Persons", color: .blue)
        }
    }
}
