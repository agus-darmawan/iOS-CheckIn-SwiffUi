//
//  AuthView.swift
//  iOS-CheckIn-App
//
//  Created by Darmawan on 19/06/25.
//

import SwiftUI

struct FaceIDAuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            if auth.isAuthenticated {
                Color.clear
            } else {
                if auth.isFaceIDAvailable {
                    ProgressView()
                        .scaleEffect(2)
                    Text("Authenticating with Face ID...")
                } else {
                    Image(systemName: "lock")
                        .font(.largeTitle)
                    Text(auth.error?.errorDescription ?? "Face ID not available")
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            auth.checkFaceIDAvailability()
        }
        .onChange(of: auth.shouldAttemptAuth) {
            if auth.shouldAttemptAuth && !auth.isAuthenticated {
                auth.authenticate()
            }
        }
        .alert("Authentication Error",
               isPresented: .constant(auth.error != nil),
               presenting: auth.error) { error in
            Button("Try Again") {
                auth.reset()
                auth.authenticate()
            }
            Button("Cancel", role: .cancel) {}
        } message: { error in
            Text(error.errorDescription ?? "Unknown error occurred")
        }
    }
}

#Preview {
    FaceIDAuthView()
}
