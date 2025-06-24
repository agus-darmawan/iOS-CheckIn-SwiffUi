//
//  FaceDetectionResult.swift
//  checkin-app
//
//  Created by Darmawan on 18/06/25.
//

import Foundation
import CoreGraphics
import UIKit
import SwiftData


struct FaceDetectionResult {
    let id = UUID()
    let boundingBox: CGRect
    let confidence: Float
    let landmarks: [CGPoint]
    let matchedPerson: RegisteredFace?
    let similarity: Float
}

struct FacePosition {
    static let center = "center"
    static let left = "left"
    static let right = "right"
    static let up = "up"
    static let down = "down"
    
    static let all = [center, left, right, up, down]
    static let instructions: [String: String] = [
        center: "Look straight at the camera with a neutral expression",
        left: "Turn your head slightly to the left while keeping eyes on camera",
        right: "Turn your head slightly to the right while keeping eyes on camera",
        up: "Tilt your head slightly up while looking at the camera",
        down: "Tilt your head slightly down while looking at the camera"
    ]
    
    static let descriptions: [String: String] = [
        center: "Front View",
        left: "Left Turn",
        right: "Right Turn",
        up: "Head Up",
        down: "Head Down"
    ]
}

struct Person {
    var id: UUID
    var name: String
    var imageData: Data?
    var faceEncoding: Data?
    var dateCreated: Date
    var isActive: Bool
    
    var uiImage: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    init(name: String, imageData: Data? = nil, faceEncoding: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.imageData = imageData
        self.faceEncoding = faceEncoding
        self.dateCreated = Date()
        self.isActive = true
    }
    
    // Helper method to set image from UIImage
    mutating func setImage(_ image: UIImage) {
        self.imageData = image.jpegData(compressionQuality: 0.8)
    }
    
    // Helper methods for face encoding
    var faceDescriptor: [Float]? {
        guard let faceEncoding = faceEncoding else { return nil }
        return faceEncoding.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self))
        }
    }
    
    mutating func setFaceDescriptor(_ descriptor: [Float]) {
        self.faceEncoding = Data(bytes: descriptor, count: descriptor.count * MemoryLayout<Float>.size)
    }
}
