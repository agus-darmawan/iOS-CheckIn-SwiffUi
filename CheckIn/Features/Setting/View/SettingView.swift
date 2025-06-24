//
//  SettingView.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AttendanceSettings]
    
    @State private var workStartTime = Date()
    @State private var workEndTime = Date()
    @State private var lateTolerance = 15
    @State private var earlyLeaveTolerance = 15
    @State private var workDays: [Int] = [2, 3, 4, 5, 6] // Monday to Friday
    
    let daysOfWeek = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        Form {
            Section(header: Text("Work Hours")) {
                DatePicker("Work Start Time", selection: $workStartTime, displayedComponents: .hourAndMinute)
                DatePicker("Work End Time", selection: $workEndTime, displayedComponents: .hourAndMinute)
            }
            
            Section(header: Text("Tolerance Minutes")) {
                Stepper("Late Tolerance: \(lateTolerance) min", value: $lateTolerance, in: 0...60)
                Stepper("Early Leave Tolerance: \(earlyLeaveTolerance) min", value: $earlyLeaveTolerance, in: 0...60)
            }
            
            Section(header: Text("Work Days")) {
                ForEach(1..<8, id: \.self) { day in
                    Toggle(isOn: Binding(
                        get: { workDays.contains(day) },
                        set: { isOn in
                            if isOn {
                                if !workDays.contains(day) {
                                    workDays.append(day)
                                }
                            } else {
                                workDays.removeAll { $0 == day }
                            }
                        }
                    )) {
                        Text(daysOfWeek[day - 1])
                    }
                }
            }
            
            Section {
                Button("Save Settings") {
                    saveSettings()
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            if let existingSettings = settings.first {
                workStartTime = existingSettings.workStartTime
                workEndTime = existingSettings.workEndTime
                lateTolerance = existingSettings.lateToleranceMinutes
                earlyLeaveTolerance = existingSettings.earlyLeaveToleranceMinutes
                workDays = existingSettings.workDays
            }
        }
    }
    
    private func saveSettings() {
        if let existingSettings = settings.first {
            existingSettings.workStartTime = workStartTime
            existingSettings.workEndTime = workEndTime
            existingSettings.lateToleranceMinutes = lateTolerance
            existingSettings.earlyLeaveToleranceMinutes = earlyLeaveTolerance
            existingSettings.workDays = workDays.sorted()
        } else {
            let newSettings = AttendanceSettings(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lateToleranceMinutes: lateTolerance,
                earlyLeaveToleranceMinutes: earlyLeaveTolerance,
                workDays: workDays.sorted()
            )
            modelContext.insert(newSettings)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}
