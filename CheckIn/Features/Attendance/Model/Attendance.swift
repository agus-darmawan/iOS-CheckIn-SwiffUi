//
//  Attendance.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import Foundation
import SwiftData

@Model
class AttendanceRecord {
    var employeeId: UUID
    var date: Date
    var checkInTime: Date?
    var checkOutTime: Date?
    var status: AttendanceStatus
    var lateMinutes: Int
    var earlyLeaveMinutes: Int
    var notes: String?
    
    init(employeeId: UUID, date: Date = Date(), checkInTime: Date? = nil, checkOutTime: Date? = nil, status: AttendanceStatus = .absent, lateMinutes: Int = 0, earlyLeaveMinutes: Int = 0, notes: String? = nil) {
        self.employeeId = employeeId
        self.date = date
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.status = status
        self.lateMinutes = lateMinutes
        self.earlyLeaveMinutes = earlyLeaveMinutes
        self.notes = notes
    }
    
    // Computed properties
    var totalWorkingHours: Double {
        guard let checkIn = checkInTime, let checkOut = checkOutTime else { return 0.0 }
        return checkOut.timeIntervalSince(checkIn) / 3600.0 // Convert to hours
    }
    
    var isLate: Bool {
        return status == .late
    }
    
    var isEarlyLeave: Bool {
        return earlyLeaveMinutes > 0
    }
}

enum AttendanceStatus: String, Codable, CaseIterable {
    case present = "present"
    case absent = "absent"
    case late = "late"
    case leave = "leave"
    case holiday = "holiday"
    
    var displayName: String {
        switch self {
        case .present: return "Hadir"
        case .absent: return "Tidak Hadir"
        case .late: return "Terlambat"
        case .leave: return "Cuti"
        case .holiday: return "Libur"
        }
    }
}

@Model
class Employee {
    var id: UUID
    var name: String
    var faceDescriptor: Data?
    var department: String
    var position: String
    var isActive: Bool
    var registeredFaceId: UUID? // Link to RegisteredFace
    var createdDate: Date
    
    init(name: String, faceDescriptor: Data? = nil, department: String = "", position: String = "", isActive: Bool = true, registeredFaceId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.faceDescriptor = faceDescriptor
        self.department = department
        self.position = position
        self.isActive = isActive
        self.registeredFaceId = registeredFaceId
        self.createdDate = Date()
    }
    
    // Helper method to get linked RegisteredFace
    func getRegisteredFace(from context: ModelContext) -> RegisteredFace? {
        guard let registeredFaceId = registeredFaceId else { return nil }
        
        let descriptor = FetchDescriptor<RegisteredFace>()
        let allFaces = (try? context.fetch(descriptor)) ?? []
        
        return allFaces.first(where: { $0.id == registeredFaceId })
    }
    
    // Get today's attendance record
    func getTodayAttendance(from context: ModelContext) -> AttendanceRecord? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        let employeeId = self.id
        
        let descriptor = FetchDescriptor<AttendanceRecord>()
        let allRecords = (try? context.fetch(descriptor)) ?? []
        
        return allRecords.first { record in
            record.employeeId == employeeId && record.date >= today && record.date < tomorrow
        }
    }
}

@Model
class AttendanceSettings {
    var workStartTime: Date
    var workEndTime: Date
    var lateToleranceMinutes: Int
    var earlyLeaveToleranceMinutes: Int
    var workDays: [Int] // 1-7 for Sunday-Saturday
    var createdDate: Date
    var updatedDate: Date
    
    init(workStartTime: Date, workEndTime: Date, lateToleranceMinutes: Int = 15, earlyLeaveToleranceMinutes: Int = 15, workDays: [Int] = [2, 3, 4, 5, 6]) {
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lateToleranceMinutes = lateToleranceMinutes
        self.earlyLeaveToleranceMinutes = earlyLeaveToleranceMinutes
        self.workDays = workDays
        self.createdDate = Date()
        self.updatedDate = Date()
    }
    
    // Helper methods to get time components
    func workStartHour() -> Int {
        Calendar.current.component(.hour, from: workStartTime)
    }
    
    func workStartMinute() -> Int {
        Calendar.current.component(.minute, from: workStartTime)
    }
    
    func workEndHour() -> Int {
        Calendar.current.component(.hour, from: workEndTime)
    }
    
    func workEndMinute() -> Int {
        Calendar.current.component(.minute, from: workEndTime)
    }
    
    // Check if today is a work day
    func isWorkDay(_ date: Date = Date()) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return workDays.contains(weekday)
    }
    
    // Get work schedule description
    func workScheduleDescription() -> String {
        let dayNames = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"]
        let workDayNames = workDays.map { dayNames[$0 - 1] }
        
        let startTime = workStartTime.formatted(date: .omitted, time: .shortened)
        let endTime = workEndTime.formatted(date: .omitted, time: .shortened)
        
        return "\(workDayNames.joined(separator: ", ")) • \(startTime) - \(endTime)"
    }
}
