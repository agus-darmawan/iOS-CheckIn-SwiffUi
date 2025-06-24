//
//  TestingViewModel.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//


import SwiftUI
import SwiftData
import PhotosUI
import Vision
import CoreML

// Test Result Data Model
struct TestResult: Identifiable {
    let id = UUID()
    let testName: String
    let isSuccess: Bool
    let message: String
    let details: [String]
    let timestamp: Date
    let duration: TimeInterval
}

// Image Analysis Result
struct ImageAnalysisResult {
    let qualityScore: Float
    let sharpness: Float
    let brightness: Float
    let contrast: Float
    let livenessPotential: Float
    let faceCount: Int
    let issues: [String]
    let processingTime: TimeInterval
}

class TestViewModel: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var selectedImage: UIImage?
    @Published var selectedImageItem: PhotosPickerItem?
    @Published var imageAnalysisResult: ImageAnalysisResult?
    @Published var showDebugInfo = false
    @Published var debugInfo: [String: Any] = [:]
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    private let faceAnalyzer = FaceAnalyzer()
//    private let qualityAnalyzer = ImageQualityAnalyzer()
    private let databaseService = DatabaseService()
    private let faceNet = FaceNet()
    
    init() {
        loadSystemDebugInfo()
    }
    
    // MARK: - Image Testing
    
    func loadSelectedImage() {
        guard let item = selectedImageItem else { return }
        
        item.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self?.selectedImage = image
                        self?.analyzeTestImage(image)
                    }
                case .failure(let error):
                    self?.addTestResult(
                        name: "Image Loading",
                        success: false,
                        message: "Failed to load image: \(error.localizedDescription)",
                        details: [],
                        duration: 0
                    )
                }
                self?.selectedImageItem = nil
            }
        }
    }
    
    func analyzeTestImage(_ image: UIImage) {
        let startTime = Date()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Analyze image quality
 
            
            // Detect faces
            var faceCount = 0
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            self.faceAnalyzer.detectFaces(in: image) { results in
                faceCount = results.count
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
            
            let processingTime = Date().timeIntervalSince(startTime)

            DispatchQueue.main.async {
                
                self.addTestResult(
                    name: "Image Analysis",
                    success: faceCount > 0,
                    message: "Analyzed image: \(faceCount) faces detected",
                    details: [
                        "Processing Time: \(String(format: "%.2f", processingTime))s"
                    ],
                    duration: processingTime
                )
            }
        }
    }
    
    // MARK: - Database Testing
    
    func testDatabaseOperations(context: ModelContext) {
        let startTime = Date()
        var testDetails: [String] = []
        var success = true
        
        do {
            // Test 1: Count registered faces
            let faces = databaseService.getAllFaces(from: context)
            testDetails.append("Found \(faces.count) registered faces")
            
            // Test 2: Create test face (without saving)
            let testImageData = createTestImageData()
            let testDescriptor = createTestDescriptor()
            
            let testFace = RegisteredFace(
                name: "Test User \(Date().timeIntervalSince1970)",
                imageData: testImageData,
                faceDescriptor: testDescriptor,
                facePositions: ["center"]
            )
            
            testDetails.append("Created test face object")
            
            // Test 3: Test descriptor comparison
            if faces.count >= 2 {
                let similarity = faceAnalyzer.compareFaces(
                    descriptor1: faces[0].faceDescriptor,
                    descriptor2: faces[1].faceDescriptor
                )
                testDetails.append("Face similarity test: \(String(format: "%.3f", similarity))")
            }
            
            // Test 4: Query performance
            let queryStart = Date()
            let descriptor = FetchDescriptor<RegisteredFace>()
            let _ = try context.fetch(descriptor)
            let queryTime = Date().timeIntervalSince(queryStart)
            testDetails.append("Query time: \(String(format: "%.3f", queryTime))s")
            
        } catch {
            success = false
            testDetails.append("Error: \(error.localizedDescription)")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        addTestResult(
            name: "Database Operations",
            success: success,
            message: success ? "All database operations completed" : "Database test failed",
            details: testDetails,
            duration: duration
        )
    }
    
    // MARK: - FaceNet Model Testing
    
    func testFaceNetModel() {
        let startTime = Date()
        var testDetails: [String] = []
        
        // Create test image
        let testImage = createTestImage()
        
        faceNet.faceEmbedding(from: testImage) { [weak self] result in
            let duration = Date().timeIntervalSince(startTime)
            
            switch result {
            case .success(let embedding):
                testDetails.append("Embedding generated successfully")
                testDetails.append("Embedding size: \(embedding.count)")
                testDetails.append("Sample values: \(Array(embedding.prefix(5)))")
                
                // Test embedding comparison
                let similarity = self?.faceNet.compare(embedding1: embedding, embedding2: embedding) ?? 0.0
                testDetails.append("Self-similarity: \(String(format: "%.3f", similarity))")
                
                DispatchQueue.main.async {
                    self?.addTestResult(
                        name: "FaceNet Model",
                        success: true,
                        message: "FaceNet model working correctly",
                        details: testDetails,
                        duration: duration
                    )
                }
                
            case .failure(let error):
                testDetails.append("Error: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self?.addTestResult(
                        name: "FaceNet Model",
                        success: false,
                        message: "FaceNet model test failed",
                        details: testDetails,
                        duration: duration
                    )
                }
            }
        }
    }
    
    // MARK: - Live Detection Testing
    
    func testLiveDetection() {
        let startTime = Date()
        var testDetails: [String] = []
        
        // Test camera availability
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        testDetails.append("Camera available: \(cameraAvailable)")
        
        // Test Vision framework
        let testRequest = VNDetectFaceRectanglesRequest()
        testDetails.append("Vision framework initialized: \(testRequest.revision)")
        
        // Test performance metrics
        let testImage = createTestImage()
        faceAnalyzer.detectFaces(in: testImage) { [weak self] results in
            let duration = Date().timeIntervalSince(startTime)
            
            testDetails.append("Face detection completed in \(String(format: "%.3f", duration))s")
            testDetails.append("Faces detected: \(results.count)")
            
            DispatchQueue.main.async {
                self?.addTestResult(
                    name: "Live Detection System",
                    success: results.count > 0,
                    message: "Live detection system test completed",
                    details: testDetails,
                    duration: duration
                )
            }
        }
    }
    
    // MARK: - Comprehensive System Test
    
    func runComprehensiveTest(context: ModelContext) {
        clearResults()
        
        DispatchQueue.main.async {
            self.testDatabaseOperations(context: context)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.testFaceNetModel()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.testLiveDetection()
        }
        
    }

    
    // MARK: - Utility Functions
    
    private func addTestResult(name: String, success: Bool, message: String, details: [String], duration: TimeInterval) {
        let result = TestResult(
            testName: name,
            isSuccess: success,
            message: message,
            details: details,
            timestamp: Date(),
            duration: duration
        )
        
        DispatchQueue.main.async {
            self.testResults.append(result)
        }
    }
    
    func clearResults() {
        testResults.removeAll()
        selectedImage = nil
        imageAnalysisResult = nil
    }
    
    func exportDebugLogs() {
        let logs = generateDebugLogs()
        
        // Create shareable content
        let activityController = UIActivityViewController(
            activityItems: [logs],
            applicationActivities: nil
        )
        
        // Present activity controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func generateDebugLogs() -> String {
        var logs = "CheckIn App Debug Logs\n"
        logs += "Generated: \(Date())\n"
        logs += "========================\n\n"
        
        // System info
        logs += "SYSTEM INFORMATION:\n"
        for (key, value) in debugInfo {
            logs += "\(key): \(value)\n"
        }
        logs += "\n"
        
        // Test results
        logs += "TEST RESULTS:\n"
        for result in testResults {
            logs += "[\(result.isSuccess ? "PASS" : "FAIL")] \(result.testName)\n"
            logs += "Message: \(result.message)\n"
            logs += "Duration: \(String(format: "%.3f", result.duration))s\n"
            logs += "Timestamp: \(result.timestamp)\n"
            
            if !result.details.isEmpty {
                logs += "Details:\n"
                for detail in result.details {
                    logs += "  - \(detail)\n"
                }
            }
            logs += "\n"
        }
        
        return logs
    }
    
    private func loadSystemDebugInfo() {
        debugInfo = [
            "Device Model": UIDevice.current.model,
            "System Version": UIDevice.current.systemVersion,
            "App Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown",
            "Build Number": Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown",
            "Device Name": UIDevice.current.name,
            "Available Memory": ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024),
            "CPU Count": ProcessInfo.processInfo.processorCount,
            "Thermal State": ProcessInfo.processInfo.thermalState.rawValue
        ]
    }
    
    private func createTestImage() -> UIImage {
        // Create a simple test image with face-like features
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.lightGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Face outline (circle)
            UIColor.black.setStroke()
            let faceRect = CGRect(x: 50, y: 50, width: 100, height: 100)
            context.cgContext.strokeEllipse(in: faceRect)
            
            // Eyes
            let leftEye = CGRect(x: 70, y: 80, width: 10, height: 10)
            let rightEye = CGRect(x: 120, y: 80, width: 10, height: 10)
            context.cgContext.fillEllipse(in: leftEye)
            context.cgContext.fillEllipse(in: rightEye)
            
            // Mouth
            let mouth = CGRect(x: 90, y: 120, width: 20, height: 5)
            context.cgContext.fillEllipse(in: mouth)
        }
    }
    
    private func createTestImageData() -> Data {
        let testImage = createTestImage()
        return testImage.jpegData(compressionQuality: 0.8) ?? Data()
    }
    
    private func createTestDescriptor() -> Data {
        // Create a random test descriptor
        let descriptorSize = 128 // FaceNet embedding size
        var randomValues: [Float] = []
        
        for _ in 0..<descriptorSize {
            randomValues.append(Float.random(in: -1.0...1.0))
        }
        
        return Data(bytes: randomValues, count: randomValues.count * MemoryLayout<Float>.size)
    }
    
    // MARK: - Performance Testing
    
    func testPerformance() {
        let startTime = Date()
        let testImage = createTestImage()
        var performanceDetails: [String] = []
        
        // Test 1: Face Detection Performance
        let faceDetectionStart = Date()
        faceAnalyzer.detectFaces(in: testImage) { results in
            let faceDetectionTime = Date().timeIntervalSince(faceDetectionStart)
            performanceDetails.append("Face Detection: \(String(format: "%.3f", faceDetectionTime))s")
            
            // Test 2: Face Descriptor Extraction Performance
            if !results.isEmpty {
                let descriptorStart = Date()
                self.faceAnalyzer.extractFaceDescriptor(from: testImage) { _ in
                    let descriptorTime = Date().timeIntervalSince(descriptorStart)
                    performanceDetails.append("Descriptor Extraction: \(String(format: "%.3f", descriptorTime))s")
                    
                    // Test 3: Image Quality Analysis Performance
                    let qualityStart = Date()
                    let qualityTime = Date().timeIntervalSince(qualityStart)
                    performanceDetails.append("Quality Analysis: \(String(format: "%.3f", qualityTime))s")
                    
                    let totalTime = Date().timeIntervalSince(startTime)
                    performanceDetails.append("Total Time: \(String(format: "%.3f", totalTime))s")
                    
                    DispatchQueue.main.async {
                        self.addTestResult(
                            name: "Performance Test",
                            success: totalTime < 5.0, // Should complete within 5 seconds
                            message: "Performance testing completed",
                            details: performanceDetails,
                            duration: totalTime
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Testing
    
    func testMemoryUsage() {
        let startMemory = getMemoryUsage()
        let testImage = createTestImage()
        var memoryDetails: [String] = []
        
        memoryDetails.append("Initial Memory: \(String(format: "%.2f", startMemory)) MB")
        
        // Process multiple images to test memory
        let imageCount = 10
        for i in 0..<imageCount {
            autoreleasepool {
                faceAnalyzer.detectFaces(in: testImage) { _ in
                    // Memory intensive operation
                }
            }
        }
        
        let endMemory = getMemoryUsage()
        let memoryIncrease = endMemory - startMemory
        
        memoryDetails.append("Final Memory: \(String(format: "%.2f", endMemory)) MB")
        memoryDetails.append("Memory Increase: \(String(format: "%.2f", memoryIncrease)) MB")
        memoryDetails.append("Images Processed: \(imageCount)")
        
        addTestResult(
            name: "Memory Usage Test",
            success: memoryIncrease < 50.0, // Should not increase by more than 50MB
            message: "Memory usage test completed",
            details: memoryDetails,
            duration: 0
        )
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024.0 * 1024.0)
        } else {
            return 0.0
        }
    }
}
