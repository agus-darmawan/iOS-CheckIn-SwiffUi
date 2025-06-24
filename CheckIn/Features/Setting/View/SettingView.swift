// SettingsView.swift
// CheckIn
//
// Created by Darmawan on 25/06/25.
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
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var currentSettings: AttendanceSettings? {
        settings.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                workHoursSection
                toleranceSection
                workDaysSection
                actionSection
            }
            .navigationTitle("Attendance Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadCurrentSettings()
            }
            .alert("Settings", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var workHoursSection: some View {
        Section(header: Label("Work Hours", systemImage: "clock")) {
            HStack {
                Label("Check-in Time", systemImage: "sunrise")
                Spacer()
                DatePicker("", selection: $workStartTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            
            HStack {
                Label("Check-out Time", systemImage: "sunset")
                Spacer()
                DatePicker("", selection: $workEndTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
    }
    
    private var toleranceSection: some View {
        Section(header: Label("Time Tolerance", systemImage: "timer"),
                footer: Text("Tolerance time before being considered late or leaving early")) {
            
            HStack {
                Label("Late Tolerance", systemImage: "clock.badge.exclamationmark")
                Spacer()
                Stepper("\(lateTolerance) minutes", value: $lateTolerance, in: 0...60, step: 5)
            }
            
            HStack {
                Label("Early Leave Tolerance", systemImage: "clock.badge.xmark")
                Spacer()
                Stepper("\(earlyLeaveTolerance) minutes", value: $earlyLeaveTolerance, in: 0...60, step: 5)
            }
        }
    }
    
    private var workDaysSection: some View {
        Section(header: Label("Work Days", systemImage: "calendar"),
                footer: Text("Select work days for the week")) {
            
            ForEach(1..<8, id: \.self) { day in
                Toggle(isOn: Binding(
                    get: { workDays.contains(day) },
                    set: { isOn in
                        if isOn {
                            if !workDays.contains(day) {
                                workDays.append(day)
                                workDays.sort()
                            }
                        } else {
                            workDays.removeAll { $0 == day }
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: getDayIcon(day))
                            .foregroundColor(workDays.contains(day) ? .blue : .secondary)
                        Text(daysOfWeek[day - 1])
                    }
                }
            }
        }
    }
    
    private var actionSection: some View {
        Section {
            Button(action: saveSettings) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text("Save Settings")
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .listRowBackground(Color.clear)
            
            Button(action: resetToDefaults) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .foregroundColor(.red)
                    Text("Reset to Defaults")
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func loadCurrentSettings() {
        if let existingSettings = currentSettings {
            workStartTime = existingSettings.workStartTime
            workEndTime = existingSettings.workEndTime
            lateTolerance = existingSettings.lateToleranceMinutes
            earlyLeaveTolerance = existingSettings.earlyLeaveToleranceMinutes
            workDays = existingSettings.workDays
        }
    }
    
    private func saveSettings() {
        // Validate settings
        guard !workDays.isEmpty else {
            alertMessage = "Select at least one work day"
            showingAlert = true
            return
        }
        
        guard workStartTime < workEndTime else {
            alertMessage = "Check-in time must be earlier than check-out time"
            showingAlert = true
            return
        }
        
        if let existingSettings = currentSettings {
            existingSettings.workStartTime = workStartTime
            existingSettings.workEndTime = workEndTime
            existingSettings.lateToleranceMinutes = lateTolerance
            existingSettings.earlyLeaveToleranceMinutes = earlyLeaveTolerance
            existingSettings.workDays = workDays.sorted()
            existingSettings.updatedDate = Date()
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
            alertMessage = "Settings successfully saved"
            showingAlert = true
        } catch {
            alertMessage = "Failed to save settings: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func resetToDefaults() {
        let calendar = Calendar.current
        workStartTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        workEndTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
        lateTolerance = 15
        earlyLeaveTolerance = 15
        workDays = [2, 3, 4, 5, 6] // Monday to Friday
    }
    
    private func getDayIcon(_ day: Int) -> String {
        switch day {
        case 1: return "sun.max" // Sunday
        case 2, 3, 4, 5, 6: return "briefcase" // Weekdays
        case 7: return "moon.zzz" // Saturday
        default: return "calendar"
        }
    }
}
