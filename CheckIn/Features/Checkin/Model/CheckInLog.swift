//
//  CheckInLog.swift
//  CheckIn
//
//  Created by Akmal Ariq on 24/06/25.
//

import Foundation
import SwiftData

@Model
class CheckInLog {
    var id: UUID
    var personId: UUID
    var personName: String
    var timestamp: Date
    var type: CheckInType
    var photoData: Data?
    var isOnTime: Bool
    
    init(personId: UUID, personName: String, type: CheckInType, photoData: Data? = nil, isOnTime: Bool = true) {
        self.id = UUID()
        self.personId = personId
        self.personName = personName
        self.timestamp = Date()
        self.type = type
        self.photoData = photoData
        self.isOnTime = isOnTime
    }
}

enum CheckInType: String, CaseIterable, Codable {
    case checkIn = "Check In"
    case checkOut = "Check Out"
}
