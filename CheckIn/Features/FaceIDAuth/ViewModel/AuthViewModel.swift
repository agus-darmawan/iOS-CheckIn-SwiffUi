//
//  AuthViewModel.swift
//  iOS-CheckIn-App
//
//  Created by Darmawan on 19/06/25.
//

import LocalAuthentication
import SwiftUI

class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    private let context = LAContext()
    
    @Published var isAuthenticated = false
    @Published var error: AuthError?
    @Published private(set) var isFaceIDAvailable = false
    @Published var shouldAttemptAuth = false
    
    init() {
        checkFaceIDAvailability()
    }
    
    func checkFaceIDAvailability() {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        DispatchQueue.main.async {
            self.isFaceIDAvailable = (self.context.biometryType == .faceID) && canEvaluate
            self.shouldAttemptAuth = self.isFaceIDAvailable
            if let error = error {
                self.error = self.mapError(error)
            }
        }
    }
    
    func authenticate() {
        guard isFaceIDAvailable else { return }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                             localizedReason: "Authenticate to proceed") { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.error = nil
                } else {
                    self?.error = error.map { self?.mapError($0) } ?? .authenticationFailed
                }
                self?.shouldAttemptAuth = false
            }
        }
    }
    
    private func mapError(_ error: Error) -> AuthError {
        guard let laError = error as? LAError else {
            return .authenticationFailed
        }
        
        switch laError.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .locked
        case .userCancel:
            return .userCanceled
        case .appCancel:
            return .systemCanceled
        default:
            return .authenticationFailed
        }
    }
    
    func reset() {
        isAuthenticated = false
        error = nil
        shouldAttemptAuth = false
    }
}
