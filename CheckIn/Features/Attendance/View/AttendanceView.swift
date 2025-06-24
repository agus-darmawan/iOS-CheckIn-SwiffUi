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
    
    var body: some View {
        NavigationStack {
            VStack {
                headerSection
                AttendanceSummaryView(
                    presentCount: summaryData.present,
                    lateCount: summaryData.late,
                    absentCount: summaryData.absent,
                    leaveCount: summaryData.leave
                )
                .padding(.horizontal)
                
                attendanceList
            }
            .navigationTitle("Attendance")
            .onChange(of: recognizedEmployee) { _, newValue in
                handleRecognizedEmployee(newValue)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
            
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AttendanceFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
    }
    
    private var attendanceList: some View {
        List {
            ForEach(filteredEmployees) { employee in
                let record = recordForEmployee(employee)
                EmployeeAttendanceRow(employee: employee, record: record)
            }
        }
    }
    
    private var checkInOutButton: some View {
        Button(action: {
            showingCheckInOut = true
        }) {
            Image(systemName: "person.badge.plus")
        }
    }
    
//    private var faceRecognitionView: some View {
//        LiveFaceRecognitionView(modelContext: modelContext) { employee in
//            recognizedEmployee = employee
//            showingCheckInOut = false
//        }
//    }
    
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
    
    private func handleRecognizedEmployee(_ employee: Employee?) {
        guard let employee = employee else { return }
        processAttendance(for: employee)
    }
    
    private func processAttendance(for employee: Employee) {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        
        if let existingRecord = recordForEmployee(employee) {
            processCheckOut(existingRecord, now: now)
        } else {
            createCheckInRecord(employee, today: today, now: now)
        }
    }
    
    private func processCheckOut(_ record: AttendanceRecord, now: Date) {
        if record.checkInTime != nil && record.checkOutTime == nil {
            record.checkOutTime = now
            calculateEarlyLeave(for: record)
            try? modelContext.save()
        }
    }
    
    private func createCheckInRecord(_ employee: Employee, today: Date, now: Date) {
        let newRecord = AttendanceRecord(employeeId: employee.id, date: today, checkInTime: now)
        calculateLateMinutes(for: newRecord)
        modelContext.insert(newRecord)
        try? modelContext.save()
    }
    
    private func calculateLateMinutes(for record: AttendanceRecord) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<AttendanceSettings>()).first else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settings.workStartTime)
        
        guard let checkInTime = record.checkInTime,
              let deadline = calendar.date(bySettingHour: components.hour!,
                                         minute: components.minute!,
                                         second: 0,
                                         of: checkInTime) else {
            return
        }
        
        if checkInTime > deadline {
            let lateMinutes = calendar.dateComponents([.minute], from: deadline, to: checkInTime).minute ?? 0
            record.lateMinutes = lateMinutes
            record.status = lateMinutes > settings.lateToleranceMinutes ? .late : .present
        } else {
            record.status = .present
        }
    }
    
    private func calculateEarlyLeave(for record: AttendanceRecord) {
        guard let settings = try? modelContext.fetch(FetchDescriptor<AttendanceSettings>()).first,
              let checkOutTime = record.checkOutTime else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settings.workEndTime)
        
        guard let deadline = calendar.date(bySettingHour: components.hour!,
                                         minute: components.minute!,
                                         second: 0,
                                         of: checkOutTime) else {
            return
        }
        
        if checkOutTime < deadline {
            let earlyMinutes = calendar.dateComponents([.minute], from: checkOutTime, to: deadline).minute ?? 0
            record.earlyLeaveMinutes = earlyMinutes
            if earlyMinutes > settings.earlyLeaveToleranceMinutes && record.status == .present {
                record.status = .leave
            }
        }
    }
}

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
        HStack {
            SummaryItem(count: presentCount, label: "Present", color: .green)
            SummaryItem(count: lateCount, label: "Late", color: .orange)
            SummaryItem(count: absentCount, label: "Absent", color: .red)
            SummaryItem(count: leaveCount, label: "Leave", color: .blue)
        }
    }
}

struct SummaryItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmployeeAttendanceRow: View {
    let employee: Employee
    let record: AttendanceRecord?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(employee.name)
                    .font(.headline)
                Text(employee.department)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let record = record {
                VStack(alignment: .trailing) {
                    Text(record.status.rawValue.capitalized)
                        .foregroundColor(statusColor(record.status))
                    
                    if let checkIn = record.checkInTime {
                        Text("In: \(checkIn.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                    }
                    
                    if let checkOut = record.checkOutTime {
                        Text("Out: \(checkOut.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                    }
                }
            } else {
                Text("Absent")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func statusColor(_ status: AttendanceStatus) -> Color {
        switch status {
        case .present: return .green
        case .late: return .orange
        case .absent: return .red
        case .leave: return .blue
        case .holiday: return .purple
        }
    }
}
