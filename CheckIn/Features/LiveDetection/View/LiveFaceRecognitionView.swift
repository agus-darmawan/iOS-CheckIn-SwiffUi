import SwiftUI
import AVFoundation
import Vision
import SwiftData

// SwiftUI wrapper for the camera view
struct LiveFaceRecognitionView: UIViewControllerRepresentable {
    let modelContext: ModelContext
    var onEmployeeRecognized: ((Employee) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController()
        cameraVC.modelContext = modelContext
        cameraVC.onEmployeeRecognized = onEmployeeRecognized
        return cameraVC
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No updates needed for this demo
    }
}

// Enhanced Liveness Detection Structure
struct LivenessDetector {
    private var eyeBlinkHistory: [TimeInterval] = []
    private var headMovementHistory: [FacePoseInfo] = []
    private var faceAreaHistory: [CGFloat] = []
    private var eyeAspectRatioHistory: [Float] = []
    
    // Thresholds
    private let eyeAspectRatioThreshold: Float = 0.25
    private let headMovementThreshold: Float = 0.15
    private let faceAreaVariationThreshold: CGFloat = 0.1
    private let minimumBlinks: Int = 2
    private let minimumHeadMovements: Int = 3
    private let historyDuration: TimeInterval = 5.0
    
    mutating func analyzeLiveness(faceObservation: VNFaceObservation, boundingBox: CGRect, poseInfo: FacePoseInfo) -> LivenessResult {
        let currentTime = Date().timeIntervalSince1970
        
        // 1. Eye Blink Detection (Enhanced)
        let eyeAspectRatio = calculateEyeAspectRatio(faceObservation: faceObservation)
        eyeAspectRatioHistory.append(eyeAspectRatio)
        
        // 2. Head Movement Detection
        headMovementHistory.append(poseInfo)
        
        // 3. Face Area Variation (depth movement)
        let faceArea = boundingBox.width * boundingBox.height
        faceAreaHistory.append(faceArea)
        
        // Clean old history
        cleanOldHistory(currentTime: currentTime)
        
        // Analyze patterns
        let blinkScore = analyzeBlinkPattern()
        let movementScore = analyzeHeadMovement()
        let depthScore = analyzeFaceAreaVariation()
        let symmetryScore = analyzeFaceSymmetry(faceObservation: faceObservation)
        let textureScore = analyzeTextureConsistency(poseInfo: poseInfo)
        
        let overallScore = (blinkScore + movementScore + depthScore + symmetryScore + textureScore) / 5.0
        
        return LivenessResult(
            isLive: overallScore > 0.6,
            confidence: overallScore,
            blinkScore: blinkScore,
            movementScore: movementScore,
            depthScore: depthScore,
            details: generateLivenessDetails(blinkScore: blinkScore, movementScore: movementScore, depthScore: depthScore)
        )
    }
    
    private func calculateEyeAspectRatio(faceObservation: VNFaceObservation) -> Float {
        guard let landmarks = faceObservation.landmarks,
              let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye else {
            return 0.0
        }
        
        // Calculate Eye Aspect Ratio (EAR)
        let leftEAR = calculateSingleEyeAspectRatio(eyePoints: leftEye.normalizedPoints)
        let rightEAR = calculateSingleEyeAspectRatio(eyePoints: rightEye.normalizedPoints)
        
        return (leftEAR + rightEAR) / 2.0
    }
    
    private func calculateSingleEyeAspectRatio(eyePoints: [CGPoint]) -> Float {
        guard eyePoints.count >= 6 else { return 0.0 }
        
        // Calculate vertical distances
        let vertical1 = distance(eyePoints[1], eyePoints[5])
        let vertical2 = distance(eyePoints[2], eyePoints[4])
        
        // Calculate horizontal distance
        let horizontal = distance(eyePoints[0], eyePoints[3])
        
        // Eye Aspect Ratio formula
        let ear = Float((vertical1 + vertical2) / (2.0 * horizontal))
        return ear
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private mutating func cleanOldHistory(currentTime: TimeInterval) {
        eyeBlinkHistory.removeAll { currentTime - $0 > historyDuration }
        
        if headMovementHistory.count > 30 {
            headMovementHistory.removeFirst(headMovementHistory.count - 30)
        }
        
        if faceAreaHistory.count > 30 {
            faceAreaHistory.removeFirst(faceAreaHistory.count - 30)
        }
        
        if eyeAspectRatioHistory.count > 30 {
            eyeAspectRatioHistory.removeFirst(eyeAspectRatioHistory.count - 30)
        }
    }
    
    private func analyzeBlinkPattern() -> Float {
        guard eyeAspectRatioHistory.count > 5 else { return 0.0 }
        
        var blinkCount = 0
        var wasBlinking = false
        
        for ear in eyeAspectRatioHistory {
            let isBlinking = ear < eyeAspectRatioThreshold
            
            if !wasBlinking && isBlinking {
                blinkCount += 1
            }
            wasBlinking = isBlinking
        }
        
        // Score based on natural blink rate (12-20 blinks per minute is normal)
        let score = min(Float(blinkCount) / Float(minimumBlinks), 1.0)
        return score
    }
    
    private func analyzeHeadMovement() -> Float {
        guard headMovementHistory.count > 3 else { return 0.0 }
        
        var movementCount = 0
        
        for i in 1..<headMovementHistory.count {
            let prev = headMovementHistory[i-1]
            let curr = headMovementHistory[i]
            
            let yawDiff = abs(curr.yaw - prev.yaw)
            let pitchDiff = abs(curr.pitch - prev.pitch)
            let rollDiff = abs(curr.roll - prev.roll)
            
            if yawDiff > headMovementThreshold || pitchDiff > headMovementThreshold || rollDiff > headMovementThreshold {
                movementCount += 1
            }
        }
        
        let score = min(Float(movementCount) / Float(minimumHeadMovements), 1.0)
        return score
    }
    
    private func analyzeFaceAreaVariation() -> Float {
        guard faceAreaHistory.count > 3 else { return 0.0 }
        
        let avgArea = faceAreaHistory.reduce(0, +) / CGFloat(faceAreaHistory.count)
        var variationCount = 0
        
        for area in faceAreaHistory {
            let variation = abs(area - avgArea) / avgArea
            if variation > faceAreaVariationThreshold {
                variationCount += 1
            }
        }
        
        let score = min(Float(variationCount) / Float(faceAreaHistory.count / 2), 1.0)
        return score
    }
    
    private func analyzeFaceSymmetry(faceObservation: VNFaceObservation) -> Float {
        guard let landmarks = faceObservation.landmarks else { return 0.5 }
        
        // Check facial symmetry to detect spoofing
        var symmetryScore: Float = 0.8 // Default good score
        
        // Check nose position relative to face center
        if let nose = landmarks.nose {
            let faceCenter = CGPoint(x: 0.5, y: 0.5)
            let noseCenter = nose.normalizedPoints.reduce(CGPoint.zero) { result, point in
                CGPoint(x: result.x + point.x, y: result.y + point.y)
            }
            let avgNose = CGPoint(x: noseCenter.x / CGFloat(nose.normalizedPoints.count),
                                y: noseCenter.y / CGFloat(nose.normalizedPoints.count))
            
            let horizontalDeviation = abs(avgNose.x - faceCenter.x)
            if horizontalDeviation > 0.1 {
                symmetryScore -= 0.2
            }
        }
        
        return symmetryScore
    }
    
    private func analyzeTextureConsistency(poseInfo: FacePoseInfo) -> Float {
        // Use confidence as a proxy for texture consistency
        // High confidence usually indicates good texture and lighting
        return poseInfo.confidence
    }
    
    private func generateLivenessDetails(blinkScore: Float, movementScore: Float, depthScore: Float) -> String {
        var details: [String] = []
        
        if blinkScore > 0.5 {
            details.append("✅ Blink")
        } else {
            details.append("❌ Blink")
        }
        
        if movementScore > 0.5 {
            details.append("✅ Movement")
        } else {
            details.append("❌ Movement")
        }
        
        if depthScore > 0.3 {
            details.append("✅ Depth")
        } else {
            details.append("❌ Depth")
        }
        
        return details.joined(separator: " | ")
    }
}

// Liveness Result Structure
struct LivenessResult {
    let isLive: Bool
    let confidence: Float
    let blinkScore: Float
    let movementScore: Float
    let depthScore: Float
    let details: String
}

// Enhanced Face Recognition Result
struct FaceRecognitionResult {
    let registeredFace: RegisteredFace?
    let similarity: Float
    let isMatch: Bool
    
    var displayName: String {
        if let face = registeredFace, isMatch {
            return face.name
        }
        return "Unknown"
    }
}

// ViewController handling the camera and face detection with enhanced liveness detection and recognition
class CameraViewController: UIViewController {
    
    private var name = ""
    
    private var drawings: [CALayer] = []
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let captureSession = AVCaptureSession()
    
    // Enhanced liveness detector
    private var livenessDetector = LivenessDetector()
    
    // Face recognition components
    private let faceAnalyzer = FaceAnalyzer()
    private let imageProcessor = ImageProcessor()
    private let databaseService = DatabaseService()
    var modelContext: ModelContext?
    var onEmployeeRecognized: ((Employee) -> Void)?
    
    // Recognition cache to avoid too frequent recognition calls
    private var lastRecognitionTime: TimeInterval = 0
    private let recognitionInterval: TimeInterval = 1.0 // Recognize every 1 second when live
    
    // Processing queue for face recognition
    private let faceRecognitionQueue = DispatchQueue(label: "face_recognition_queue", qos: .userInitiated)
    private let uiUpdateQueue = DispatchQueue.main
    
    // Cache for face recognition results to avoid repeated processing
    private var recognitionCache: [String: (result: FaceRecognitionResult, timestamp: TimeInterval)] = [:]
    private let cacheExpirationTime: TimeInterval = 3.0
    
    // Store current recognition results for UI updates
    private var currentRecognitionResults: [String: FaceRecognitionResult] = [:]
    
    // ATTENDANCE INTEGRATION
    private let attendanceService = AttendanceService()
    private var lastAttendanceTime: TimeInterval = 0
    private let attendanceInterval: TimeInterval = 5.0 // 5 seconds minimum between attendance records
    private var isProcessingAttendance = false
    
    // Feedback untuk user
    private var attendanceResultLayer: CATextLayer?
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCameraInput()
        showCameraFeed()
        captureFrames()
        captureSession.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    private func setupCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first else {
            fatalError("No camera detected. Please use a real camera, not a simulator.")
        }
        
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        captureSession.addInput(cameraInput)
    }
    
    private func showCameraFeed() {
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
    
    private func captureFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        captureSession.addOutput(videoDataOutput)
        
        guard let connection = videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported else {
            return
        }
        
        connection.videoOrientation = .portrait
    }
    
    private func detectFace(image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { vnRequest, error in
            if let error = error {
                print("❌ Face detection error: \(error)")
                return
            }
            
            self.uiUpdateQueue.async {
                if let results = vnRequest.results as? [VNFaceObservation], results.count > 0 {
                    self.handleFaceDetectionResults(observedFaces: results, originalImage: image)
                } else {
                    self.clearDrawings()
                    self.currentRecognitionResults.removeAll()
                }
            }
        }
        
        faceDetectionRequest.revision = VNDetectFaceLandmarksRequestRevision3
        let imageResultHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        
        do {
            try imageResultHandler.perform([faceDetectionRequest])
        } catch {
            print("❌ Face detection request failed: \(error)")
        }
    }
    
    private func extractFacePoseInfo(from faceObservation: VNFaceObservation) -> FacePoseInfo {
        var yaw: Float = 0.0
        var pitch: Float = 0.0
        var roll: Float = 0.0
        
        if let yawAngle = faceObservation.roll {
            yaw = yawAngle.floatValue
        }
        
        if let pitchAngle = faceObservation.pitch {
            pitch = pitchAngle.floatValue
        }
        
        if let rollAngle = faceObservation.yaw {
            roll = rollAngle.floatValue
        }
        
        let confidence = faceObservation.confidence
        
        return FacePoseInfo(
            yaw: yaw,
            pitch: pitch,
            roll: roll,
            confidence: confidence
        )
    }

    private func handleFaceDetectionResults(observedFaces: [VNFaceObservation], originalImage: CVPixelBuffer) {
        clearDrawings()
        
        for (index, observedFace) in observedFaces.enumerated() {
            let faceBoundingBoxOnScreen = previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            
            let poseInfo = extractFacePoseInfo(from: observedFace)
            
            // Enhanced liveness detection
            let livenessResult = livenessDetector.analyzeLiveness(
                faceObservation: observedFace,
                boundingBox: faceBoundingBoxOnScreen,
                poseInfo: poseInfo
            )
            
            // Generate unique face key
            let faceKey = "\(index)_\(Int(faceBoundingBoxOnScreen.origin.x))_\(Int(faceBoundingBoxOnScreen.origin.y))"
            
            // Get existing recognition result if available
            var recognitionResult = currentRecognitionResults[faceKey]
            
            // Perform face recognition only if liveness is detected and enough time has passed
            if livenessResult.isLive {
                let currentTime = Date().timeIntervalSince1970
                if currentTime - lastRecognitionTime > recognitionInterval {
                    // Generate cache key based on face position
                    let cacheKey = "\(Int(faceBoundingBoxOnScreen.origin.x))_\(Int(faceBoundingBoxOnScreen.origin.y))"
                    
                    // Check cache first
                    if let cached = recognitionCache[cacheKey],
                       currentTime - cached.timestamp < cacheExpirationTime {
                        recognitionResult = cached.result
                        currentRecognitionResults[faceKey] = cached.result
                    } else {
                        // Perform recognition asynchronously
                        performFaceRecognitionAsync(
                            from: originalImage,
                            faceObservation: observedFace,
                            cacheKey: cacheKey,
                            faceKey: faceKey,
                            faceBoundingBox: faceBoundingBoxOnScreen
                        )
                    }
                    lastRecognitionTime = currentTime
                }
            } else {
                // Remove recognition result if face is not live
                currentRecognitionResults.removeValue(forKey: faceKey)
                recognitionResult = nil
            }
            
            // Create bounding box with live status
            let faceBoundingBoxShape = createBoundingBox(
                boundingBox: faceBoundingBoxOnScreen,
                isLive: livenessResult.isLive,
                confidence: livenessResult.confidence,
                recognitionResult: recognitionResult
            )
            
            // Create live indicator overlay
            if livenessResult.isLive {
                let liveIndicator = createLiveIndicator(
                    boundingBox: faceBoundingBoxOnScreen,
                    recognitionResult: recognitionResult
                )
                view.layer.addSublayer(liveIndicator)
                drawings.append(liveIndicator)
            }
            
            view.layer.addSublayer(faceBoundingBoxShape)
            
            drawings.append(faceBoundingBoxShape)
        }
    }
    
    private func performFaceRecognitionAsync(from pixelBuffer: CVPixelBuffer, faceObservation: VNFaceObservation, cacheKey: String, faceKey: String, faceBoundingBox: CGRect) {
        guard let modelContext = modelContext else { return }
        
        faceRecognitionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let result = self.performFaceRecognition(from: pixelBuffer, faceObservation: faceObservation)
            
            // Cache the result
            if let result = result {
                let currentTime = Date().timeIntervalSince1970
                self.recognitionCache[cacheKey] = (result: result, timestamp: currentTime)
                
                // Clean old cache entries
                self.cleanRecognitionCache(currentTime: currentTime)
                
                // Update UI on main thread
                self.uiUpdateQueue.async {
                    self.currentRecognitionResults[faceKey] = result
                    self.updateRecognitionUI(result: result, faceBoundingBox: faceBoundingBox)
                    
                    // ATTENDANCE INTEGRATION: Process attendance if face is recognized
                    if result.isMatch, let recognizedFace = result.registeredFace {
                        self.handleSuccessfulRecognition(recognizedFace)
                    }
                }
            }
        }
    }
    
    // ATTENDANCE INTEGRATION: Process attendance when face is recognized
    private func handleSuccessfulRecognition(_ registeredFace: RegisteredFace) {
        guard let modelContext = modelContext else {
            print("❌ ModelContext not available for attendance")
            return
        }
        
        let currentTime = Date().timeIntervalSince1970
        
        // Prevent too frequent attendance processing
        guard currentTime - lastAttendanceTime > attendanceInterval else {
            print("⏳ Attendance interval not met, skipping")
            return
        }
        
        // Prevent multiple simultaneous processing
        guard !isProcessingAttendance else {
            print("⏳ Already processing attendance, skipping")
            return
        }
        
        isProcessingAttendance = true
        lastAttendanceTime = currentTime
        
        print("🔄 Processing attendance for recognized face: \(registeredFace.name)")
        
        // Process attendance in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let result = self.attendanceService.processAttendance(for: registeredFace, modelContext: modelContext)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.isProcessingAttendance = false
                self.showAttendanceResult(result)
                
                // Call the callback with employee if provided
                if result.success, let employee = self.attendanceService.getEmployeeForRegisteredFace(registeredFace, modelContext: modelContext) {
                    self.onEmployeeRecognized?(employee)
                }
                
                // Generate haptic feedback
                if result.success {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
    
    // ATTENDANCE INTEGRATION: Show attendance result to user
    private func showAttendanceResult(_ result: AttendanceProcessResult) {
        // Remove existing result layer
        attendanceResultLayer?.removeFromSuperlayer()
        
        // Create new result layer
        let resultLayer = CATextLayer()
        
        let actionText = result.action == .checkIn ? "CHECK-IN" : "CHECK-OUT"
        let statusIcon = result.success ? "✅" : "❌"
        let displayText = """
        \(statusIcon) \(actionText)
        👤 \(result.employee)
        📅 \(Date().formatted(date: .abbreviated, time: .shortened))
        
        \(result.message)
        """
        
        resultLayer.string = displayText
        resultLayer.fontSize = 14
        resultLayer.foregroundColor = UIColor.white.cgColor
        resultLayer.backgroundColor = result.success ?
            UIColor.systemGreen.withAlphaComponent(0.9).cgColor :
            UIColor.systemRed.withAlphaComponent(0.9).cgColor
        resultLayer.cornerRadius = 12
        resultLayer.alignmentMode = .center
        resultLayer.contentsScale = UIScreen.main.scale
        resultLayer.borderWidth = 2
        resultLayer.borderColor = UIColor.white.cgColor
        
        // Position at center-bottom of screen
        let resultWidth: CGFloat = 280
        let resultHeight: CGFloat = 120
        resultLayer.frame = CGRect(
            x: (view.frame.width - resultWidth) / 2,
            y: view.frame.height - resultHeight - 100,
            width: resultWidth,
            height: resultHeight
        )
        
        view.layer.addSublayer(resultLayer)
        attendanceResultLayer = resultLayer
        
        // Add slide-up animation
        let slideAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        slideAnimation.fromValue = 100
        slideAnimation.toValue = 0
        slideAnimation.duration = 0.3
        slideAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        resultLayer.add(slideAnimation, forKey: "slideUp")
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.fromValue = 1.0
            fadeAnimation.toValue = 0.0
            fadeAnimation.duration = 0.5
            fadeAnimation.fillMode = .forwards
            fadeAnimation.isRemovedOnCompletion = false
            
            self.attendanceResultLayer?.add(fadeAnimation, forKey: "fadeOut")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.attendanceResultLayer?.removeFromSuperlayer()
                self.attendanceResultLayer = nil
            }
        }
    }
    
    private func cleanRecognitionCache(currentTime: TimeInterval) {
        recognitionCache = recognitionCache.filter { _, value in
            currentTime - value.timestamp < cacheExpirationTime
        }
    }
    
    private func updateRecognitionUI(result: FaceRecognitionResult, faceBoundingBox: CGRect) {
        // Log detection result
        if result.isMatch {
            name = result.displayName
            print("✅ Face Recognized: \(result.displayName) (Similarity: \(String(format: "%.2f%%", result.similarity * 100)))")
        } else {
            print("❓ Unknown Face Detected (Highest Similarity: \(String(format: "%.2f%%", result.similarity * 100)))")
        }
    }
    
    private func performFaceRecognition(from pixelBuffer: CVPixelBuffer, faceObservation: VNFaceObservation) -> FaceRecognitionResult? {
        guard let modelContext = modelContext else {
            print("❌ ModelContext not available")
            return nil
        }
        
        // Convert CVPixelBuffer to UIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Failed to create CGImage from CVPixelBuffer")
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        
        // Get all registered faces from database
        let registeredFaces = databaseService.getAllFaces(from: modelContext)
        
        print("📊 Registered faces count: \(registeredFaces.count)")
        
        guard !registeredFaces.isEmpty else {
            print("⚠️ No registered faces in database")
            return FaceRecognitionResult(registeredFace: nil, similarity: 0.0, isMatch: false)
        }
        
        var bestMatch: RegisteredFace?
        var highestSimilarity: Float = 0.0
        let similarityThreshold: Float = 0.7 // Adjust this threshold as needed
        
        // Extract face descriptor from current frame using semaphore for synchronous operation
        let semaphore = DispatchSemaphore(value: 0)
        var currentDescriptor: Data?
        
        faceAnalyzer.extractFaceDescriptor(from: uiImage) { descriptorData in
            currentDescriptor = descriptorData
            semaphore.signal()
        }
        
        // Wait for descriptor extraction with timeout
        let result = semaphore.wait(timeout: .now() + 2.0)
        
        guard result == .success, let currentDesc = currentDescriptor else {
            print("⚠️ Face descriptor extraction timed out or failed")
            return FaceRecognitionResult(registeredFace: nil, similarity: 0.0, isMatch: false)
        }
        
        print("✅ Face descriptor extracted successfully")
        
        // Compare with all registered faces
        for registeredFace in registeredFaces {
            let similarity = faceAnalyzer.compareFaces(
                descriptor1: currentDesc,
                descriptor2: registeredFace.faceDescriptor
            )
            
            print("👤 Comparing with \(registeredFace.name): similarity = \(String(format: "%.2f", similarity))")
            
            if similarity > highestSimilarity {
                highestSimilarity = similarity
                bestMatch = registeredFace
            }
        }
        
        let isMatch = highestSimilarity > similarityThreshold
        
        if isMatch, let match = bestMatch {
            name = match.name
            print("🎯 Best match: \(match.name) with similarity: \(String(format: "%.2f", highestSimilarity))")
        } else {
            print("❌ No match found. Highest similarity: \(String(format: "%.2f", highestSimilarity))")
        }
        
        return FaceRecognitionResult(
            registeredFace: bestMatch,
            similarity: highestSimilarity,
            isMatch: isMatch
        )
    }
    
    private func createBoundingBox(boundingBox: CGRect, isLive: Bool, confidence: Float, recognitionResult: FaceRecognitionResult?) -> CAShapeLayer {
        let faceBoundingBoxPath = CGPath(rect: boundingBox, transform: nil)
        let faceBoundingBoxShape = CAShapeLayer()
        faceBoundingBoxShape.path = faceBoundingBoxPath
        faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
        faceBoundingBoxShape.lineWidth = 3.0
        
        // Color based on liveness and recognition
        if isLive {
            if let result = recognitionResult, result.isMatch {
                // Known person - use blue color
                faceBoundingBoxShape.strokeColor = UIColor.systemBlue.cgColor
                
                // Add animated glow effect for recognized faces
                let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
                glowAnimation.fromValue = 0.0
                glowAnimation.toValue = 0.8
                glowAnimation.duration = 1.0
                glowAnimation.autoreverses = true
                glowAnimation.repeatCount = .infinity
                
                faceBoundingBoxShape.shadowColor = UIColor.systemBlue.cgColor
                faceBoundingBoxShape.shadowRadius = 10
                faceBoundingBoxShape.shadowOffset = CGSize.zero
                faceBoundingBoxShape.add(glowAnimation, forKey: "glow")
            } else {
                // Live but unknown person - green color
                faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
                
                let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
                glowAnimation.fromValue = 0.0
                glowAnimation.toValue = 0.8
                glowAnimation.duration = 1.0
                glowAnimation.autoreverses = true
                glowAnimation.repeatCount = .infinity
                
                faceBoundingBoxShape.shadowColor = UIColor.green.cgColor
                faceBoundingBoxShape.shadowRadius = 10
                faceBoundingBoxShape.shadowOffset = CGSize.zero
                faceBoundingBoxShape.add(glowAnimation, forKey: "glow")
            }
        } else {
            faceBoundingBoxShape.strokeColor = UIColor.red.cgColor
        }
        
        return faceBoundingBoxShape
    }
    
    private func createLiveIndicator(boundingBox: CGRect, recognitionResult: FaceRecognitionResult?) -> CATextLayer {
        let liveIndicator = CATextLayer()
        liveIndicator.string = "👤 \(name.isEmpty ? "Unknown" : name)"
        liveIndicator.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9).cgColor
        
        liveIndicator.fontSize = 16
        liveIndicator.foregroundColor = UIColor.white.cgColor
        liveIndicator.cornerRadius = 8
        liveIndicator.alignmentMode = .center
        liveIndicator.contentsScale = UIScreen.main.scale
        
        let indicatorWidth: CGFloat = 120
        let indicatorHeight: CGFloat = 30
        liveIndicator.frame = CGRect(
            x: boundingBox.maxX - indicatorWidth - 10,
            y: boundingBox.minY + 10,
            width: indicatorWidth,
            height: indicatorHeight
        )
        
        // Add pulsing animation
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.duration = 0.8
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        liveIndicator.add(pulseAnimation, forKey: "pulse")
        
        return liveIndicator
    }
    
    private func createEnhancedTextLayer(poseInfo: FacePoseInfo, boundingBox: CGRect, faceIndex: Int, livenessResult: LivenessResult, recognitionResult: FaceRecognitionResult?) -> CATextLayer {
        let textLayer = CATextLayer()
        
        let yawDegrees = poseInfo.yaw * 180 / Float.pi
        let pitchDegrees = poseInfo.pitch * 180 / Float.pi
        let rollDegrees = poseInfo.roll * 180 / Float.pi
        
        let headDirection = getHeadPoseDescription(yaw: poseInfo.yaw, pitch: poseInfo.pitch, roll: poseInfo.roll)
        
        var recognitionText = ""
        if livenessResult.isLive {
            recognitionText = name
        }
        
        let poseText = String(format: """
        👤 Wajah %d
        🎯 %@
        
        %@
        
        📊 Detail Pose:
        ↔️ Yaw: %.1f°
        ↕️ Pitch: %.1f°
        🔄 Roll: %.1f°
        ✅ Conf: %.2f
        
        🔍 Liveness: %@
        📈 Score: %.2f
        %@
        """,
        faceIndex + 1,
        headDirection,
        recognitionText,
        yawDegrees,
        pitchDegrees,
        rollDegrees,
        poseInfo.confidence,
        livenessResult.isLive ? "HIDUP ✅" : "TIDAK HIDUP ❌",
        livenessResult.confidence,
        livenessResult.details
        )
        
        textLayer.string = poseText
        textLayer.fontSize = 11
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.backgroundColor = UIColor.black.withAlphaComponent(0.8).cgColor
        textLayer.cornerRadius = 6
        textLayer.alignmentMode = .left
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.borderWidth = 1
        
        // Set border color based on recognition status
        if livenessResult.isLive {
            if let result = recognitionResult, result.isMatch {
                textLayer.borderColor = UIColor.systemBlue.cgColor
            } else {
                textLayer.borderColor = UIColor.green.cgColor
            }
        } else {
            textLayer.borderColor = UIColor.red.cgColor
        }
        
        let textWidth: CGFloat = 220
        let textHeight: CGFloat = 200
        textLayer.frame = CGRect(
            x: boundingBox.minX,
            y: max(0, boundingBox.minY - textHeight - 10),
            width: textWidth,
            height: textHeight
        )
        
        return textLayer
    }
    
    private func getHeadPoseDescription(yaw: Float, pitch: Float, roll: Float) -> String {
        let yawDegrees = yaw * 180 / Float.pi
        let pitchDegrees = pitch * 180 / Float.pi
        let rollDegrees = roll * 180 / Float.pi
        
        var directions: [String] = []
        
        if abs(yawDegrees) > 10 {
            if yawDegrees > 0 {
                directions.append("👉 Kanan")
            } else {
                directions.append("👈 Kiri")
            }
        }
        
        if abs(pitchDegrees) > 10 {
            if pitchDegrees > 0 {
                directions.append("👆 Atas")
            } else {
                directions.append("👇 Bawah")
            }
        }
        
        if abs(rollDegrees) > 15 {
            if rollDegrees > 0 {
                directions.append("↗️ Miring Kanan")
            } else {
                directions.append("↖️ Miring Kiri")
            }
        }
        
        if directions.isEmpty {
            return "🎯 Lurus"
        }
        
        return directions.joined(separator: " + ")
    }
    
    private func clearDrawings() {
        drawings.forEach { drawing in
            drawing.removeFromSuperlayer()
        }
        drawings.removeAll()
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        detectFace(image: frame)
    }
}

// Define the FacePoseInfo struct
struct FacePoseInfo {
    let yaw: Float
    let pitch: Float
    let roll: Float
    let confidence: Float
}
