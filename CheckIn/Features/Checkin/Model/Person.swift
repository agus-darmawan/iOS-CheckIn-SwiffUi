//
//  Person.swift
//  CheckIn
//
//  Created by Akmal Ariq on 24/06/25.
//

import Foundation
import SwiftData

@Model
class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    var leaveCount: Int
    var photoData: Data?
    var checkInLogs: [CheckInLog]
    
    init(name: String, leaveCount: Int = 1, photoData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.leaveCount = leaveCount
        self.photoData = photoData
        self.checkInLogs = []
    }
}
