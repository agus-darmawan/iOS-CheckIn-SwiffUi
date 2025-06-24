//
//  AttendanceView.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftUI
import SwiftData

struct AttendanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var employees: [Employee]
    @Query private var records: [AttendanceRecord]
    @Query private var settings: [AttendanceSettings]
    
    @StateObject private var attendanceService = AttendanceService()
    
    @State private var selectedDate = Date()
    @State private var selectedFilter: AttendanceFilter = .today
    @State private var showingCheckInOut = false
    @State private var recognizedEmployee: Employee?
    
    // Extracted computed properties
    private var filteredEmployees: [Employee] {
        employees.filter { $0.isActive }
    }
    
    private var filteredRecords: [AttendanceRecord] {
        switch selectedFilter {
        case .today:
            return recordsForToday()
        case .thisWeek:
            return recordsForThisWeek()
        case .thisMonth:
            return recordsForThisMonth()
        }
    }
    
    private var summaryData: (present: Int, late: Int, absent: Int, leave: Int) {
        let presentCount = filteredRecords.filter { $0.status == .present }.count
        let lateCount = filteredRecords.filter { $0.status == .late }.count
        let absentCount = filteredRecords.filter { $0.status == .absent }.count
        let leaveCount = filteredRecords.filter { $0.status == .leave }.count
        return (presentCount, lateCount, absentCount, leaveCount)
    }
    
    private var currentSettings: AttendanceSettings? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                
                // Summary Cards
                AttendanceSummaryView(
                    presentCount: summaryData.present,
                    lateCount: summaryData.late,
                    absentCount: summaryData.absent,
                    leaveCount: summaryData.leave
                )
                .padding(.horizontal)
                
                // Attendance List
                attendanceList
            }
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingCheckInOut) {
                NavigationView {
                    LiveFaceRecognitionView(modelContext: modelContext) { employee in
                        recognizedEmployee = employee
                        showingCheckInOut = false
                    }
                    .navigationTitle("Face Recognition")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showingCheckInOut = false
                            }
                        }
                    }
                }
            }
            .onChange(of: recognizedEmployee) { _, newValue in
                handleRecognizedEmployee(newValue)
            }
            .onAppear {
                // Create default settings if needed
                attendanceService.createDefaultSettingsIfNeeded(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                
                Spacer()
                
                if let settings = currentSettings {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Working Hours")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(settings.workStartTime.formatted(date: .omitted, time: .shortened)) - \(settings.workEndTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AttendanceFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    
    private var attendanceList: some View {
        List {
            if filteredEmployees.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "No Employees Yet",
                    description: "Please register employee faces first"
                )
            } else {
                ForEach(filteredEmployees) { employee in
                    let record = recordForEmployee(employee)
                    EmployeeAttendanceRow(employee: employee, record: record)
                }
            }
            
            // Today's Records Section
            if selectedFilter == .today && !filteredRecords.isEmpty {
                Section("Today's History") {
                    ForEach(filteredRecords.sorted(by: {
                        ($0.checkInTime ?? Date.distantPast) > ($1.checkInTime ?? Date.distantPast)
                    })) { record in
                        if let employee = getEmployee(for: record.employeeId) {
                            TodayAttendanceRow(record: record, employee: employee)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Helper Methods
    
    private func recordsForToday() -> [AttendanceRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private func recordsForThisWeek() -> [AttendanceRecord] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else {
            return []
        }
        return records.filter { weekInterval.contains($0.date) }
    }
    
    private func recordsForThisMonth() -> [AttendanceRecord] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: selectedDate) else {
            return []
        }
        return records.filter { monthInterval.contains($0.date) }
    }
    
    private func recordForEmployee(_ employee: Employee) -> AttendanceRecord? {
        records.first { $0.employeeId == employee.id && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private func getEmployee(for employeeId: UUID) -> Employee? {
        employees.first { $0.id == employeeId }
    }
    
    private func handleRecognizedEmployee(_ employee: Employee?) {
        // Employee recognition handled automatically by LiveFaceRecognitionView
    }
}

// MARK: - Supporting Views

enum AttendanceFilter: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
}

struct AttendanceSummaryView: View {
    let presentCount: Int
    let lateCount: Int
    let absentCount: Int
    let leaveCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            SummaryItem(count: presentCount, label: "Present", color: .green, icon: "checkmark.circle.fill")
            SummaryItem(count: lateCount, label: "Late", color: .orange, icon: "clock.fill")
            SummaryItem(count: absentCount, label: "Absent", color: .red, icon: "xmark.circle.fill")
            SummaryItem(count: leaveCount, label: "Leave", color: .blue, icon: "person.fill.questionmark")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct SummaryItem: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct EmployeeAttendanceRow: View {
    let employee: Employee
    let record: AttendanceRecord?
    
    var body: some View {
        HStack(spacing: 12) {
            // Employee Avatar
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(employee.name.prefix(2).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !employee.department.isEmpty || !employee.position.isEmpty {
                    HStack {
                        if !employee.department.isEmpty {
                            Text(employee.department)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !employee.position.isEmpty {
                            Text("• \(employee.position)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let record = record {
                    StatusBadge(status: record.status)
                    
                    if let checkIn = record.checkInTime {
                        Text("In: \(checkIn.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let checkOut = record.checkOutTime {
                        Text("Out: \(checkOut.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if record.lateMinutes > 0 {
                        Text("Late by \(record.lateMinutes) minutes")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else {
                    StatusBadge(status: .absent)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: AttendanceStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case .present: return .green
        case .late: return .orange
        case .absent: return .red
        case .leave: return .blue
        case .holiday: return .purple
        }
    }
}

struct TodayAttendanceRow: View {
    let record: AttendanceRecord
    let employee: Employee
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    if let checkIn = record.checkInTime {
                        Label(checkIn.formatted(date: .omitted, time: .shortened), systemImage: "arrow.right.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if let checkOut = record.checkOutTime {
                        Label(checkOut.formatted(date: .omitted, time: .shortened), systemImage: "arrow.left.circle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                StatusBadge(status: record.status)
                
                if record.totalWorkingHours > 0 {
                    Text("\(String(format: "%.1f", record.totalWorkingHours)) hours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
