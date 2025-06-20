//
//  MainButtonView.swift
//  checkin-app
//
//  Created by Akmal Ariq on 17/06/25.
//

import SwiftUI

struct MainButtonView: View {
    let tab: MainTab
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: tab.iconName)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(tab.color)
                .frame(width: 60, height: 60)
                .background(tab.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(tab.title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(tab.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct MainButtonView_Previews: PreviewProvider {
    static var previews: some View {
        MainButtonView(tab: .enroll)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
