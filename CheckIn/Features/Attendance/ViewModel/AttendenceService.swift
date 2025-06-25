//
//  AttendanceService.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftData
import Foundation

class AttendanceService: ObservableObject {
    
    // MARK: - Main Attendance Processing
    
    // Process attendance when a face is recognized
    func processAttendance(for registeredFace: RegisteredFace, modelContext: ModelContext) -> AttendanceProcessResult {
        print("🔄 Processing attendance for: \(registeredFace.name)")
        
        // Find or create employee linked to this registered face
        let employee = findOrCreateEmployee(for: registeredFace, modelContext: modelContext)
        
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        
        // Check if it's a work day
        if let settings = getAttendanceSettings(modelContext: modelContext) {
            if !settings.isWorkDay(now) {
                return AttendanceProcessResult(
                    success: false,
                    message: "Hari ini bukan hari kerja",
                    action: .checkIn,
                    employee: employee.name
                )
            }
        }
        
        // Check if there's already a record for today
        if let existingRecord = getAttendanceRecord(for: employee, date: today, modelContext: modelContext) {
            return processCheckOut(existingRecord, now: now, modelContext: modelContext)
        } else {
            return createCheckInRecord(for: employee, today: today, now: now, modelContext: modelContext)
        }
    }
    
    // MARK: - Employee Management
    
    // Find employee linked to registered face or create new one
    func findOrCreateEmployee(for registeredFace: RegisteredFace, modelContext: ModelContext) -> Employee {
        // First try to find existing employee linked to this registered face
        let faceId = registeredFace.id
        
        let descriptor = FetchDescriptor<Employee>()
        let allEmployees = (try? modelContext.fetch(descriptor)) ?? []
        
        if let existingEmployee = allEmployees.first(where: { $0.registeredFaceId == faceId }) {
            print("✅ Found existing employee: \(existingEmployee.name)")
            return existingEmployee
        }
        
        // Create new employee if not found
        print("📝 Creating new employee for: \(registeredFace.name)")
        let newEmployee = Employee(
            name: registeredFace.name,
            faceDescriptor: registeredFace.faceDescriptor,
            registeredFaceId: registeredFace.id
        )
        
        modelContext.insert(newEmployee)
        
        do {
            try modelContext.save()
            print("✅ New employee created and saved")
        } catch {
            print("❌ Failed to save new employee: \(error)")
        }
        
        return newEmployee
    }
    
    // Get employee for registered face
    func getEmployeeForRegisteredFace(_ registeredFace: RegisteredFace, modelContext: ModelContext) -> Employee? {
        let faceId = registeredFace.id
        
        let descriptor = FetchDescriptor<Employee>()
        let allEmployees = (try? modelContext.fetch(descriptor)) ?? []
        
        return allEmployees.first(where: { $0.registeredFaceId == faceId })
    }
    
    // MARK: - Attendance Records
    
    // Get attendance record for specific employee and date
    func getAttendanceRecord(for employee: Employee, date: Date, modelContext: ModelContext) -> AttendanceRecord? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let employeeId = employee.id
        
        let descriptor = FetchDescriptor<AttendanceRecord>()
        let allRecords = (try? modelContext.fetch(descriptor)) ?? []
        
        return allRecords.first { record in
            record.employeeId == employeeId && record.date >= startOfDay && record.date < endOfDay
        }
    }
    
    // Get all attendance records for employee in date range
    func getAttendanceRecords(for employee: Employee, from startDate: Date, to endDate: Date, modelContext: ModelContext) -> [AttendanceRecord] {
        let employeeId = employee.id
        
        let descriptor = FetchDescriptor<AttendanceRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let allRecords = (try? modelContext.fetch(descriptor)) ?? []
        
        return allRecords.filter { record in
            record.employeeId == employeeId && record.date >= startDate && record.date <= endDate
        }
    }
    
    // MARK: - Check-in/Check-out Processing
    
    // Process check-out
    private func processCheckOut(_ record: AttendanceRecord, now: Date, modelContext: ModelContext) -> AttendanceProcessResult {
        if record.checkInTime != nil && record.checkOutTime == nil {
            print("⏰ Processing check-out for: \(record.employeeId)")
            record.checkOutTime = now
            
            calculateEarlyLeave(for: record, modelContext: modelContext)
            
            do {
                try modelContext.save()
                print("✅ Check-out processed successfully")
                
                let workingHours = record.totalWorkingHours
                let hoursText = String(format: "%.1f jam", workingHours)
                
                return AttendanceProcessResult(
                    success: true,
                    message: "Check-out successful on \(now.formatted(date: .omitted, time: .shortened))\nTotal kerja: \(hoursText)",
                    action: .checkOut,
                    employee: getEmployeeName(for: record.employeeId, modelContext: modelContext)
                )
            } catch {
                print("❌ Failed to save check-out: \(error)")
                return AttendanceProcessResult(
                    success: false,
                    message: "Failed to record checkout: \(error.localizedDescription)",
                    action: .checkOut,
                    employee: getEmployeeName(for: record.employeeId, modelContext: modelContext)
                )
            }
        } else {
            print("⚠️ Invalid check-out attempt")
            let message = record.checkOutTime != nil ? "Anda sudah check-out hari ini" : "Belum melakukan check-in"
            return AttendanceProcessResult(
                success: false,
                message: message,
                action: .checkOut,
                employee: getEmployeeName(for: record.employeeId, modelContext: modelContext)
            )
        }
    }
    
    // Create check-in record
    private func createCheckInRecord(for employee: Employee, today: Date, now: Date, modelContext: ModelContext) -> AttendanceProcessResult {
        print("📝 Creating check-in record for: \(employee.name)")
        
        let newRecord = AttendanceRecord(employeeId: employee.id, date: today, checkInTime: now)
        
        calculateLateMinutes(for: newRecord, modelContext: modelContext)
        
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
            print("✅ Check-in processed successfully")
            
            let statusText = newRecord.isLate ? " (You're late \(newRecord.lateMinutes) minutes)" : ""
            
            return AttendanceProcessResult(
                success: true,
                message: "Check-in successful on \(now.formatted(date: .omitted, time: .shortened))\(statusText)",
                action: .checkIn,
                employee: employee.name
            )
        } catch {
            print("❌ Failed to save check-in: \(error)")
            return AttendanceProcessResult(
                success: false,
                message: "Failed to in: \(error.localizedDescription)",
                action: .checkIn,
                employee: employee.name
            )
        }
    }
    
    // MARK: - Time Calculations
    
    // Calculate late minutes
    private func calculateLateMinutes(for record: AttendanceRecord, modelContext: ModelContext) {
        guard let settings = getAttendanceSettings(modelContext: modelContext),
              let checkInTime = record.checkInTime else {
            print("⚠️ No settings or check-in time found")
            return
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settings.workStartTime)
        
        guard let deadline = calendar.date(bySettingHour: components.hour!,
                                         minute: components.minute!,
                                         second: 0,
                                         of: checkInTime) else {
            print("❌ Failed to calculate work start deadline")
            return
        }
        
        if checkInTime > deadline {
            let lateMinutes = calendar.dateComponents([.minute], from: deadline, to: checkInTime).minute ?? 0
            record.lateMinutes = lateMinutes
            record.status = lateMinutes > settings.lateToleranceMinutes ? .late : .present
            print("⏰ Late by \(lateMinutes) minutes")
        } else {
            record.status = .present
            print("✅ On time")
        }
    }
    
    // Calculate early leave
    private func calculateEarlyLeave(for record: AttendanceRecord, modelContext: ModelContext) {
        guard let settings = getAttendanceSettings(modelContext: modelContext),
              let checkOutTime = record.checkOutTime else {
            print("⚠️ No settings or check-out time found")
            return
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: settings.workEndTime)
        
        guard let deadline = calendar.date(bySettingHour: components.hour!,
                                         minute: components.minute!,
                                         second: 0,
                                         of: checkOutTime) else {
            print("❌ Failed to calculate work end deadline")
            return
        }
        
        if checkOutTime < deadline {
            let earlyMinutes = calendar.dateComponents([.minute], from: checkOutTime, to: deadline).minute ?? 0
            record.earlyLeaveMinutes = earlyMinutes
            if earlyMinutes > settings.earlyLeaveToleranceMinutes && record.status == .present {
                record.status = .leave
            }
            print("⏰ Early leave by \(earlyMinutes) minutes")
        } else {
            print("✅ Regular checkout time")
        }
    }
    
    // MARK: - Settings Management
    
    // Get attendance settings
    func getAttendanceSettings(modelContext: ModelContext) -> AttendanceSettings? {
        let descriptor = FetchDescriptor<AttendanceSettings>()
        return try? modelContext.fetch(descriptor).first
    }
    
    // Create default settings if not exists
    func createDefaultSettingsIfNeeded(modelContext: ModelContext) {
        if getAttendanceSettings(modelContext: modelContext) == nil {
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
    
    // MARK: - Utility Methods
    
    // Get employee name by ID
    private func getEmployeeName(for employeeId: UUID, modelContext: ModelContext) -> String {
        let descriptor = FetchDescriptor<Employee>()
        let allEmployees = (try? modelContext.fetch(descriptor)) ?? []
        
        if let employee = allEmployees.first(where: { $0.id == employeeId }) {
            return employee.name
        }
        return "Unknown"
    }
    
    // Get all employees
    func getAllEmployees(modelContext: ModelContext) -> [Employee] {
        let descriptor = FetchDescriptor<Employee>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        let allEmployees = (try? modelContext.fetch(descriptor)) ?? []
        return allEmployees.filter { $0.isActive }
    }
    
    // Get all attendance records for today
    func getTodayAttendanceRecords(modelContext: ModelContext) -> [AttendanceRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let descriptor = FetchDescriptor<AttendanceRecord>(
            sortBy: [SortDescriptor(\.checkInTime, order: .reverse)]
        )
        
        let allRecords = (try? modelContext.fetch(descriptor)) ?? []
        
        return allRecords.filter { record in
            record.date >= today && record.date < tomorrow
        }
    }
}

// MARK: - Supporting Structures

// Result structure for attendance processing
struct AttendanceProcessResult {
    let success: Bool
    let message: String
    let action: AttendanceAction
    let employee: String
}

enum AttendanceAction {
    case checkIn
    case checkOut
}
