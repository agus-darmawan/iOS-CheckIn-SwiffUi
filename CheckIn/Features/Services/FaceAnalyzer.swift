//
//  FaceAnalyzer.swift
//  checkin-app
//
//  Created by Darmawan on 18/06/25.
//

import Vision
import UIKit
import CoreML

class FaceAnalyzer {
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    private let faceNet = FaceNet() // Use FaceNet for embeddings
    
    // Configurable thresholds
    var similarityThreshold: Float = 0.7
    var recognitionInterval: TimeInterval = 1.0
    var livenessThreshold: Float = 0.6
    
    init() {
        // Configure face detection requests
        faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
        faceLandmarksRequest.revision = VNDetectFaceLandmarksRequestRevision3
        
        print("✅ FaceAnalyzer initialized with thresholds:")
        print("  Similarity: \(similarityThreshold)")
        print("  Liveness: \(livenessThreshold)")
    }
    
    func detectFaces(in image: UIImage, completion: @escaping ([FaceDetectionResult]) -> Void) {
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage from UIImage")
            completion([])
            return
        }
        
        print("🔍 Starting face detection...")
        
        let requests: [VNRequest] = [faceDetectionRequest, faceLandmarksRequest]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform(requests)
                let results = self.processDetectionResults()
                print("✅ Face detection complete, found \(results.count) faces")
                DispatchQueue.main.async {
                    completion(results)
                }
            } catch {
                print("❌ Face detection error: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    func extractFaceDescriptor(from image: UIImage, completion: @escaping (Data?) -> Void) {
        print("🔄 Starting face descriptor extraction...")
        print("📏 Input image size: \(image.size)")
        
        // First detect faces to get the best face region
        detectFaces(in: image) { [weak self] results in
            guard let self = self else {
                print("❌ Self is nil during descriptor extraction")
                completion(nil)
                return
            }
            
            print("🔍 Detected \(results.count) faces for descriptor extraction")
            
            guard let bestFace = self.selectBestFace(from: results) else {
                print("❌ No suitable face found for descriptor extraction")
                completion(nil)
                return
            }
            
            print("✅ Selected best face with confidence: \(bestFace.confidence)")
            print("📍 Face bounding box: \(bestFace.boundingBox)")
            
            // Crop and prepare face image
            guard let faceImage = self.cropAndPrepareFace(from: image, boundingBox: bestFace.boundingBox) else {
                print("❌ Failed to crop and prepare face")
                completion(nil)
                return
            }
            
            print("✅ Face prepared successfully, size: \(faceImage.size)")
            
            // Extract embedding using FaceNet
            self.faceNet.faceEmbedding(from: faceImage) { result in
                switch result {
                case .success(let embedding):
                    print("✅ Successfully generated embedding with \(embedding.count) dimensions")
                    // Convert [Float] to Data
                    let data = Data(bytes: embedding, count: embedding.count * MemoryLayout<Float>.size)
                    completion(data)
                case .failure(let error):
                    print("❌ FaceNet embedding error: \(error)")
                    completion(nil)
                }
            }
        }
    }
    
    private func selectBestFace(from results: [FaceDetectionResult]) -> FaceDetectionResult? {
        guard !results.isEmpty else { return nil }
        
        // Select face with highest confidence and reasonable size
        return results.max { face1, face2 in
            let area1 = face1.boundingBox.width * face1.boundingBox.height
            let area2 = face2.boundingBox.width * face2.boundingBox.height
            
            // Prefer larger faces with higher confidence
            let score1 = face1.confidence * Float(area1)
            let score2 = face2.confidence * Float(area2)
            
            return score1 < score2
        }
    }
    
    private func cropAndPrepareFace(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage for cropping")
            return nil
        }
        
        print("🔄 Cropping and preparing face...")
        print("📏 Original image size: \(image.size)")
        print("📍 Bounding box: \(boundingBox)")
        
        // Convert Vision coordinates (normalized, origin bottom-left) to UIImage coordinates
        let imageSize = image.size
        let rect = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        
        print("📍 Converted rect: \(rect)")
        
        // Add padding around the face (25% padding for better context)
        let padding: CGFloat = 0.25
        let paddedRect = CGRect(
            x: max(0, rect.origin.x - rect.width * padding),
            y: max(0, rect.origin.y - rect.height * padding),
            width: min(imageSize.width - max(0, rect.origin.x - rect.width * padding),
                      rect.width * (1 + 2 * padding)),
            height: min(imageSize.height - max(0, rect.origin.y - rect.height * padding),
                       rect.height * (1 + 2 * padding))
        )
        
        print("📍 Padded rect: \(paddedRect)")
        
        // Ensure the rect is within image bounds
        let clampedRect = CGRect(
            x: max(0, min(paddedRect.origin.x, imageSize.width - 1)),
            y: max(0, min(paddedRect.origin.y, imageSize.height - 1)),
            width: min(paddedRect.width, imageSize.width - max(0, paddedRect.origin.x)),
            height: min(paddedRect.height, imageSize.height - max(0, paddedRect.origin.y))
        )
        
        print("📍 Final clamped rect: \(clampedRect)")
        
        // Validate rect dimensions
        guard clampedRect.width > 0 && clampedRect.height > 0 else {
            print("❌ Invalid cropping rectangle dimensions")
            return nil
        }
        
        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            print("❌ Failed to crop CGImage")
            return nil
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        print("✅ Face cropped successfully, final size: \(croppedImage.size)")
        
        // Apply additional preprocessing for better recognition
        return preprocessFaceImage(croppedImage)
    }
    
    private func preprocessFaceImage(_ image: UIImage) -> UIImage {
        // Apply basic image enhancement for better recognition
        // This could include histogram equalization, noise reduction, etc.
        // For now, we'll just ensure proper orientation and size
        
        let enhancedImage = image.fixedOrientation()
        
        // Ensure minimum size for FaceNet
        let minSize: CGFloat = 160
        if enhancedImage.size.width < minSize || enhancedImage.size.height < minSize {
            let scale = max(minSize / enhancedImage.size.width, minSize / enhancedImage.size.height)
            let newSize = CGSize(width: enhancedImage.size.width * scale, height: enhancedImage.size.height * scale)
            return enhancedImage.resized(to: newSize) ?? enhancedImage
        }
        
        return enhancedImage
    }
    
    func compareFaces(descriptor1: Data, descriptor2: Data) -> Float {
        guard descriptor1.count == descriptor2.count else {
            print("❌ Descriptor size mismatch: \(descriptor1.count) vs \(descriptor2.count)")
            return 0.0
        }
        
        let count = descriptor1.count / MemoryLayout<Float>.size
        let array1 = descriptor1.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self).prefix(count))
        }
        let array2 = descriptor2.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self).prefix(count))
        }
        
        print("🔍 Comparing embeddings of size \(array1.count)")
        
        // Use FaceNet's comparison method (cosine similarity)
        let similarity = faceNet.compare(embedding1: array1, embedding2: array2)
        
        print("📊 Comparison result: \(similarity)")
        
        return similarity
    }
    
    // Alternative comparison using Euclidean distance
    func compareFacesEuclidean(descriptor1: Data, descriptor2: Data) -> Float {
        guard descriptor1.count == descriptor2.count else {
            print("❌ Descriptor size mismatch: \(descriptor1.count) vs \(descriptor2.count)")
            return 0.0
        }
        
        let count = descriptor1.count / MemoryLayout<Float>.size
        let array1 = descriptor1.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self).prefix(count))
        }
        let array2 = descriptor2.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self).prefix(count))
        }
        
        return faceNet.compareEuclidean(embedding1: array1, embedding2: array2)
    }
    
    // Method to find best match from a list of registered faces
    func findBestMatch(for currentDescriptor: Data, among registeredFaces: [RegisteredFace]) -> (face: RegisteredFace?, similarity: Float) {
        guard !registeredFaces.isEmpty else {
            print("⚠️ No registered faces to compare against")
            return (nil, 0.0)
        }
        
        print("🔍 Comparing against \(registeredFaces.count) registered faces")
        
        var bestMatch: RegisteredFace?
        var highestSimilarity: Float = 0.0
        
        for face in registeredFaces {
            let similarity = compareFaces(descriptor1: currentDescriptor, descriptor2: face.faceDescriptor)
            
            print("  \(face.name): \(similarity)")
            
            if similarity > highestSimilarity {
                highestSimilarity = similarity
                bestMatch = face
            }
        }
        
        if let best = bestMatch {
            print("🎯 Best match: \(best.name) with similarity: \(highestSimilarity)")
        } else {
            print("❌ No matches found")
        }
        
        return (bestMatch, highestSimilarity)
    }
    
    private func processDetectionResults() -> [FaceDetectionResult] {
        var results: [FaceDetectionResult] = []
        
        if let faceResults = faceDetectionRequest.results {
            for observation in faceResults {
                let boundingBox = observation.boundingBox
                let confidence = observation.confidence
                
                // Skip faces with very low confidence
                guard confidence > 0.3 else { continue }
                
                var landmarks: [CGPoint] = []
                if let landmarkResults = faceLandmarksRequest.results {
                    for landmarkObservation in landmarkResults {
                        // Match faces by checking if bounding boxes are similar
                        if abs(landmarkObservation.boundingBox.origin.x - boundingBox.origin.x) < 0.05 &&
                           abs(landmarkObservation.boundingBox.origin.y - boundingBox.origin.y) < 0.05 {
                            landmarks = extractLandmarks(from: landmarkObservation)
                            break
                        }
                    }
                }
                
                let result = FaceDetectionResult(
                    boundingBox: boundingBox,
                    confidence: confidence,
                    landmarks: landmarks,
                    matchedPerson: nil,
                    similarity: 0.0
                )
                results.append(result)
            }
        }
        
        return results
    }
    
    private func extractLandmarks(from observation: VNFaceObservation) -> [CGPoint] {
        var points: [CGPoint] = []
        
        if let landmarks = observation.landmarks {
            if let faceContour = landmarks.faceContour {
                points.append(contentsOf: faceContour.normalizedPoints)
            }
            if let leftEye = landmarks.leftEye {
                points.append(contentsOf: leftEye.normalizedPoints)
            }
            if let rightEye = landmarks.rightEye {
                points.append(contentsOf: rightEye.normalizedPoints)
            }
            if let nose = landmarks.nose {
                points.append(contentsOf: nose.normalizedPoints)
            }
            if let outerLips = landmarks.outerLips {
                points.append(contentsOf: outerLips.normalizedPoints)
            }
        }
        
        return points
    }
    
    // Quality assessment for face images
    func assessFaceQuality(image: UIImage) -> FaceQualityAssessment {
        var score: Float = 1.0
        var issues: [String] = []
        
        // Check image size
        let minSize: CGFloat = 100
        if image.size.width < minSize || image.size.height < minSize {
            score -= 0.3
            issues.append("Image too small")
        }
        
        // Check if image is too blurry (simplified check)
        let aspectRatio = image.size.width / image.size.height
        if aspectRatio < 0.7 || aspectRatio > 1.5 {
            score -= 0.2
            issues.append("Unusual aspect ratio")
        }
        
        return FaceQualityAssessment(score: max(0, score), issues: issues)
    }
}

struct FaceQualityAssessment {
    let score: Float
    let issues: [String]
    
    var isGoodQuality: Bool {
        return score >= 0.7
    }
}
