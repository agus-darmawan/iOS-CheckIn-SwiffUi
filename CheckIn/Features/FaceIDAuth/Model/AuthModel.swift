//
//  Auth.swift
//  iOS-CheckIn-App
//
//  Created by Darmawan on 19/06/25.
//

import Foundation

enum AuthError: Error, LocalizedError {
    case notAvailable
    case notEnrolled
    case locked
    case authenticationFailed
    case userCanceled
    case systemCanceled
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Face ID is not available on this device"
        case .notEnrolled:
            return "Face ID is not set up on this device"
        case .locked:
            return "Face ID is locked (too many failed attempts)"
        case .authenticationFailed:
            return "Face ID authentication failed"
        case .userCanceled:
            return "Authentication was canceled by user"
        case .systemCanceled:
            return "Authentication was canceled by system"
        }
    }
}
