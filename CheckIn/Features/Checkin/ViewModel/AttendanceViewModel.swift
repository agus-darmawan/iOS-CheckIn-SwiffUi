//
//  AttendanceViewModel.swift
//  CheckIn
//
//  Created by Akmal Ariq on 24/06/25.
//
import Foundation
import SwiftData
import SwiftUI

@Observable
class AttendanceViewModel {
    var modelContext: ModelContext?
    var people: [Person] = []
    var checkInLogs: [CheckInLog] = []
    var showingAlert = false
    var alertMessage = ""
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchPeople()
        fetchCheckInLogs()
    }
    
    // MARK: - Enroll Functions
    func enrollPerson(name: String, leaveCount: Int = 1, photoData: Data?) {
        guard let context = modelContext else { return }
        
        let person = Person(name: name, leaveCount: leaveCount, photoData: photoData)
        context.insert(person)
        
        do {
            try context.save()
            fetchPeople()
            showAlert("Person enrolled successfully!")
        } catch {
            showAlert("Failed to enroll person: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Check In/Out Functions
    func checkIn(personId: UUID, photoData: Data?) {
        guard let context = modelContext,
              let person = people.first(where: { $0.id == personId }) else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // Check if it's valid check-in time (6:00 AM - 8:15 AM)
        let isOnTime = (hour >= 6 && hour < 8) || (hour == 8 && minute <= 15)
        
        // If not on time, reduce leave count
        if !isOnTime {
            person.leaveCount = max(0, person.leaveCount - 1)
        }
        
        let log = CheckInLog(
            personId: personId,
            personName: person.name,
            type: .checkIn,
            photoData: photoData,
            isOnTime: isOnTime
        )
        
        context.insert(log)
        person.checkInLogs.append(log)
        
        do {
            try context.save()
            fetchPeople()
            fetchCheckInLogs()
            showAlert("Check-in successful!")
        } catch {
            showAlert("Failed to check in: \(error.localizedDescription)")
        }
    }
    
    func checkOut(personId: UUID, photoData: Data?) {
        guard let context = modelContext,
              let person = people.first(where: { $0.id == personId }) else { return }
        
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Check if it's valid check-out time (12:00 PM - 6:00 PM)
        let isOnTime = hour >= 12 && hour < 18
        
        // If not on time, reduce leave count
        if !isOnTime {
            person.leaveCount = max(0, person.leaveCount - 1)
        }
        
        let log = CheckInLog(
            personId: personId,
            personName: person.name,
            type: .checkOut,
            photoData: photoData,
            isOnTime: isOnTime
        )
        
        context.insert(log)
        person.checkInLogs.append(log)
        
        do {
            try context.save()
            fetchPeople()
            fetchCheckInLogs()
            showAlert("Check-out successful!")
        } catch {
            showAlert("Failed to check out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Functions
    func fetchPeople() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\.name)])
            people = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch people: \(error)")
        }
    }
    
    func fetchCheckInLogs() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<CheckInLog>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            checkInLogs = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch check-in logs: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    func isValidCheckInTime() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        return (hour >= 6 && hour < 8) || (hour == 8 && minute <= 15)
    }
    
    func isValidCheckOutTime() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        return hour >= 12 && hour < 18
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
