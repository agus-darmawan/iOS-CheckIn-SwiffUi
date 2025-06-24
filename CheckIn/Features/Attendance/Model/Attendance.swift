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
}

enum AttendanceStatus: String, Codable {
    case present
    case absent
    case late
    case leave
    case holiday
}

@Model
class Employee {
    var id: UUID
    var name: String
    var faceDescriptor: Data?
    var department: String
    var position: String
    var isActive: Bool
    
    init(name: String, faceDescriptor: Data? = nil, department: String = "", position: String = "", isActive: Bool = true) {
        self.id = UUID()
        self.name = name
        self.faceDescriptor = faceDescriptor
        self.department = department
        self.position = position
        self.isActive = isActive
    }
}

@Model
class AttendanceSettings {
    var workStartTime: Date
    var workEndTime: Date
    var lateToleranceMinutes: Int
    var earlyLeaveToleranceMinutes: Int
    var workDays: [Int] // 1-7 for Sunday-Saturday
    
    init(workStartTime: Date, workEndTime: Date, lateToleranceMinutes: Int = 15, earlyLeaveToleranceMinutes: Int = 15, workDays: [Int] = [2, 3, 4, 5, 6]) {
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.lateToleranceMinutes = lateToleranceMinutes
        self.earlyLeaveToleranceMinutes = earlyLeaveToleranceMinutes
        self.workDays = workDays
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
}
