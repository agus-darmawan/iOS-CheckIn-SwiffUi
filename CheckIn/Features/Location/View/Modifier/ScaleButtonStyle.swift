//
//  ScaleButtonStyle.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("Press Me") {}
            .buttonStyle(ScaleButtonStyle())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
