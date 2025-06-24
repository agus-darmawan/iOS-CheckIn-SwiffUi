//
//  FaceNet.swift
//  checkin-app
//
//  Created by Darmawan on 18/06/25.
//


import CoreML
import Vision
import Accelerate
import UIKit

class FaceNet {
    private var coreMLModel: FaceNetModel?
    private let targetImageSize = CGSize(width: 160, height: 160)
    
    init() {
        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            self.coreMLModel = try FaceNetModel(configuration: configuration)
            print("✅ FaceNet model loaded successfully")
        } catch {
            print("❌ Failed to initialize FaceNet model: \(error)")
        }
    }
    
    func faceEmbedding(from image: UIImage, completion: @escaping (Result<[Float], Error>) -> Void) {
        guard let model = coreMLModel else {
            print("❌ FaceNet model not loaded")
            completion(.failure(FaceNetError.modelNotLoaded))
            return
        }
        
        print("🔄 Processing image for FaceNet embedding...")
        print("📏 Original image size: \(image.size)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Convert UIImage to MLMultiArray with shape [1, 160, 160, 3]
                guard let multiArray = try self.prepareImageForModel(image: image) else {
                    print("❌ Failed to prepare image for model")
                    throw FaceNetError.imageProcessingFailed
                }
                
                print("✅ Image prepared successfully, shape: \(multiArray.shape)")
                
                // Create input for CoreML model
                let input = FaceNetModelInput(input: multiArray)
                
                // Make prediction
                let output = try model.prediction(input: input)
                let embedding = self.normalizeEmbedding(output.embeddings)
                
                print("✅ Embedding generated successfully, size: \(embedding.count)")
                print("📊 Embedding sample: \(Array(embedding.prefix(5)))")
                
                DispatchQueue.main.async {
                    completion(.success(embedding))
                }
            } catch {
                print("❌ FaceNet prediction error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func prepareImageForModel(image: UIImage) throws -> MLMultiArray? {
        // Resize image to target size (160x160)
        guard let resizedImage = image.resized(to: targetImageSize) else {
            print("❌ Failed to resize image")
            return nil
        }
        
        print("✅ Image resized to: \(resizedImage.size)")
        
        // Convert to CGImage
        guard let cgImage = resizedImage.cgImage else {
            print("❌ Failed to get CGImage")
            return nil
        }
        
        // Create MLMultiArray with shape [1, 160, 160, 3] for batch processing
        let shape = [1, 160, 160, 3] as [NSNumber]
        guard let multiArray = try? MLMultiArray(shape: shape, dataType: .float32) else {
            print("❌ Failed to create MLMultiArray with shape \(shape)")
            return nil
        }
        
        print("📐 Created MLMultiArray with shape: \(multiArray.shape)")
        
        // Create color space and context for pixel extraction
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: 160,
            height: 160,
            bitsPerComponent: 8,
            bytesPerRow: 160 * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("❌ Failed to create CGContext")
            return nil
        }
        
        // Draw image into context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 160, height: 160))
        
        guard let pixelData = context.data else {
            print("❌ Failed to get pixel data")
            return nil
        }
        
        // Fill multiarray with normalized pixel values
        // Shape: [1, 160, 160, 3] where:
        // - 1 is batch size
        // - 160x160 are height and width
        // - 3 are RGB channels
        let data = pixelData.bindMemory(to: UInt8.self, capacity: 160 * 160 * 4)
        
        for h in 0..<160 {
            for w in 0..<160 {
                let pixelIndex = (h * 160 + w) * 4
                
                // Get RGB values (skip alpha channel)
                let r = Float(data[pixelIndex]) / 255.0
                let g = Float(data[pixelIndex + 1]) / 255.0
                let b = Float(data[pixelIndex + 2]) / 255.0
                
                // FaceNet expects normalized RGB values in range [0, 1]
                // The array indices correspond to: [batch, height, width, channel]
                let rIndex = [0, h, w, 0] as [NSNumber]  // R channel
                let gIndex = [0, h, w, 1] as [NSNumber]  // G channel
                let bIndex = [0, h, w, 2] as [NSNumber]  // B channel
                
                multiArray[rIndex] = NSNumber(value: r)
                multiArray[gIndex] = NSNumber(value: g)
                multiArray[bIndex] = NSNumber(value: b)
            }
        }
        
        // Debug: print some pixel values and array info
        print("🔍 Array details:")
        print("  Shape: \(multiArray.shape)")
        print("  Data type: \(multiArray.dataType)")
        print("  Count: \(multiArray.count)")
        
        // Sample some pixel values for verification
        print("🔍 Sample pixel values:")
        for i in 0..<min(9, multiArray.count) { // Sample first 9 values
            print("  Index \(i): \(multiArray[i])")
        }
        
        // Verify the shape is correct
        let expectedSize = 1 * 160 * 160 * 3
        if multiArray.count != expectedSize {
            print("⚠️ Warning: Array size \(multiArray.count) doesn't match expected size \(expectedSize)")
        }
        
        return multiArray
    }
    
    private func normalizeEmbedding(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        var embedding = [Float](repeating: 0, count: count)
        
        // Extract values from MLMultiArray
        for i in 0..<count {
            embedding[i] = Float(truncating: multiArray[i])
        }
        
        print("🔍 Raw embedding stats:")
        let minVal = embedding.min() ?? 0
        let maxVal = embedding.max() ?? 0
        let meanVal = embedding.reduce(0, +) / Float(count)
        print("  Min: \(minVal), Max: \(maxVal), Mean: \(meanVal)")
        
        // Normalize the vector to unit length (L2 normalization)
        var magnitude: Float = 0
        vDSP_svesq(embedding, 1, &magnitude, vDSP_Length(count))
        magnitude = sqrt(magnitude)
        
        print("  Magnitude before normalization: \(magnitude)")
        
        if magnitude > 0 {
            vDSP_vsdiv(embedding, 1, &magnitude, &embedding, 1, vDSP_Length(count))
        }
        
        // Verify normalization
        var newMagnitude: Float = 0
        vDSP_svesq(embedding, 1, &newMagnitude, vDSP_Length(count))
        newMagnitude = sqrt(newMagnitude)
        print("  Magnitude after normalization: \(newMagnitude)")
        
        return embedding
    }
    
    func compare(embedding1: [Float], embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else {
            print("❌ Embedding size mismatch: \(embedding1.count) vs \(embedding2.count)")
            return 0.0
        }
        
        var dotProduct: Float = 0
        vDSP_dotpr(embedding1, 1, embedding2, 1, &dotProduct, vDSP_Length(embedding1.count))
        
        print("🔍 Dot product: \(dotProduct)")
        
        // For normalized embeddings, cosine similarity equals dot product
        // Convert from [-1, 1] range to [0, 1] range for easier interpretation
        let similarity = (dotProduct + 1.0) / 2.0
        
        // Alternative: Use raw dot product if embeddings are normalized
        // let similarity = max(0, dotProduct) // Clamp to [0, 1]
        
        print("🔍 Final similarity score: \(similarity)")
        
        return similarity
    }
    
    // Alternative comparison method using Euclidean distance
    func compareEuclidean(embedding1: [Float], embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else {
            print("❌ Embedding size mismatch: \(embedding1.count) vs \(embedding2.count)")
            return 0.0
        }
        
        var distance: Float = 0
        for i in 0..<embedding1.count {
            let diff = embedding1[i] - embedding2[i]
            distance += diff * diff
        }
        distance = sqrt(distance)
        
        // Convert distance to similarity (inverse relationship)
        // Typical FaceNet distances are in range [0, 2] for normalized embeddings
        let similarity = max(0, 1.0 - (distance / 2.0))
        
        print("🔍 Euclidean distance: \(distance), similarity: \(similarity)")
        
        return similarity
    }
    
    enum FaceNetError: Error {
        case modelNotLoaded
        case predictionFailed
        case imageProcessingFailed
        
        var localizedDescription: String {
            switch self {
            case .modelNotLoaded:
                return "FaceNet model not loaded"
            case .predictionFailed:
                return "Failed to predict face embedding"
            case .imageProcessingFailed:
                return "Failed to process input image"
            }
        }
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // High quality resizing with proper aspect ratio handling
    func resizedWithAspectFit(to size: CGSize) -> UIImage? {
        let aspectRatio = self.size.width / self.size.height
        let targetAspectRatio = size.width / size.height
        
        var newSize = size
        if aspectRatio > targetAspectRatio {
            // Image is wider, fit to width
            newSize.height = size.width / aspectRatio
        } else {
            // Image is taller, fit to height
            newSize.width = size.height * aspectRatio
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Fill background with black
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Center the image
            let x = (size.width - newSize.width) / 2
            let y = (size.height - newSize.height) / 2
            
            self.draw(in: CGRect(x: x, y: y, width: newSize.width, height: newSize.height))
        }
    }
}
