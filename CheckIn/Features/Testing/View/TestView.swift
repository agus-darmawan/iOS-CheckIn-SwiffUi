//
//  TestView.swift
//  CheckIn
//
//  Created by Darmawan on 20/06/25.
//

import SwiftUI

struct TestView: View {
    let title: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(color)
                .padding(.bottom, 20)
            
            Text("Hello from \(title) page!")
                .font(.title)
                .fontWeight(.medium)
            
            Text("This is a dummy view for demonstration purposes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TestView(title: "Test", color: .blue)
        }
    }
}
