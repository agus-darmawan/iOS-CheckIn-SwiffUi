//
//  RegisteredFace.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftData
import SwiftUI
import Foundation

@Model
class RegisteredFace {
    var id: UUID
    var name: String
    var imageData: Data
    var faceDescriptor: Data
    var registrationDate: Date
    var facePositions: [String]
    
    init(name: String, imageData: Data, faceDescriptor: Data, facePositions: [String] = []) {
        self.id = UUID()
        self.name = name
        self.imageData = imageData
        self.faceDescriptor = faceDescriptor
        self.registrationDate = Date()
        self.facePositions = facePositions
    }
    
    var uiImage: UIImage? {
        return UIImage(data: imageData)
    }
}

