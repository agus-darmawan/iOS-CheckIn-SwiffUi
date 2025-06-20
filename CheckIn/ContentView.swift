//
//  ContentView.swift
//  CheckIn
//
//  Created by Darmawan on 20/06/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MainTab? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Choose an action to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
                        ForEach(MainTab.allCases, id: \.self) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                MainButtonView(tab: tab)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationDestination(item: $selectedTab) { tab in
                    switch tab {
                    case .enroll: TestView(title: "Enroll", color: .red)
                    case .location: LocationView()
                    case .persons: TestView(title: "Person", color: .blue)
                    case .capture: TestView(title: "Person", color: .blue)
                    case .attribute: TestView(title: "Person", color: .blue)
                    case .settings: TestView(title: "Person", color: .blue)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
