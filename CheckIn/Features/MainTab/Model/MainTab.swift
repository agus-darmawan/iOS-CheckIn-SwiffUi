//
//  MainTab.swift
//  checkin-app
//
//  Created by Akmal Ariq on 17/06/25.
//

//
//  MainTab.swift
//  checkin-app
//
//  Created by Akmal Ariq on 17/06/25.
//

import SwiftUI

enum MainTab: String, CaseIterable, Identifiable, Hashable {
    case attendance
    case enroll
    case capture
    case settings
    case persons
    case developerTools
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .attendance: return "Attendance"
        case .enroll: return "Enroll"
        case .capture: return "Capture"
        case .settings: return "Settings"
        case .persons: return "Persons"
        case .developerTools: return "Developer Tools"
        }
    }
    
    var subtitle: String {
        switch self {
        case .attendance: return "Record attendance"
        case .enroll: return "Register new face"
        case .capture: return "Live attendance capture"
        case .settings: return "App configuration"
        case .persons: return "View all registered persons"
        case .developerTools: return "Developer tools for testing during developement"
        }
    }
    
    var iconName: String {
        switch self {
        case .attendance: return "clock.fill"
        case .enroll: return "person.badge.plus"
        case .capture: return "camera.fill"
        case .settings: return "gearshape.fill"
        case .persons: return "person.3.fill"
        case .developerTools: return "tag.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .attendance: return .teal
        case .enroll: return .blue
        case .capture: return .orange
        case .settings: return .gray
        case .persons: return .indigo
        case .developerTools: return .purple
        }
    }
}
