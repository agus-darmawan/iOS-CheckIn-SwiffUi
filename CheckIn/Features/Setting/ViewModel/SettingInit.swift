//
//  SettingsInitializer.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftData
import Foundation

class SettingsInitializer {
    static func createDefaultSettings(modelContext: ModelContext) {
        // Check if settings already exist
        let descriptor = FetchDescriptor<AttendanceSettings>()
        
        if let existingSettings = try? modelContext.fetch(descriptor).first {
            print("✅ Settings already exist")
            return
        }
        
        // Create default settings (8 AM - 5 PM, Monday-Friday)
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
        
        let defaultSettings = AttendanceSettings(
            workStartTime: startTime,
            workEndTime: endTime,
            lateToleranceMinutes: 15,
            earlyLeaveToleranceMinutes: 15,
            workDays: [2, 3, 4, 5, 6] // Monday to Friday
        )
        
        modelContext.insert(defaultSettings)
        
        do {
            try modelContext.save()
            print("✅ Default settings created")
        } catch {
            print("❌ Failed to create default settings: \(error)")
        }
    }
}
