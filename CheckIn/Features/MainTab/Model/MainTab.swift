//
//  MainTab.swift
//  checkin-app
//
//  Created by Akmal Ariq on 17/06/25.
//

import SwiftUI

enum MainTab: String, CaseIterable, Identifiable, Hashable {
    case enroll
    case location
    case capture
    case attribute
    case settings
    case persons
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .enroll: return "Enroll"
        case .location: return "Location"
        case .capture: return "Capture"
        case .attribute: return "Attribute"
        case .settings: return "Settings"
        case .persons: return "Persons"
        }
    }
    
    var subtitle: String {
        switch self {
        case .enroll: return "Register new entries"
        case .location: return "Find Location"
        case .capture: return "Record information"
        case .attribute: return "Manage characteristics"
        case .settings: return "App configuration"
        case .persons: return "View all persons"
        }
    }
    
    var iconName: String {
        switch self {
        case .enroll: return "person.badge.plus"
        case .location: return "location.fill"
        case .capture: return "camera.fill"
        case .attribute: return "tag.fill"
        case .settings: return "gearshape.fill"
        case .persons: return "person.3.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .enroll: return .blue
        case .location: return .green
        case .capture: return .orange
        case .attribute: return .purple
        case .settings: return .gray
        case .persons: return .indigo
        }
    }
}
