//
//  WelcomeHeaderView.swift
//  CheckIn
//
//  Created by Akmal Ariq on 20/06/25.
//

import SwiftUI

struct MainTabView: View {
    let handleSelection: (MainTab) -> Void

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible())]

    var body: some View {
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
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Button {
                        handleSelection(tab)
                    } label: {
                        MainButtonView(tab: tab)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

import SwiftUI

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(handleSelection: { tab in
            print("Selected tab: \(tab)")
        })
        .previewLayout(.sizeThatFits)  // Adjusts the preview layout to fit the content
        .padding() 
    }
}
