//
//  FaceRegistrationViewModel.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//

import SwiftUI
import PhotosUI
import SwiftData
import Vision
import CoreML

class FaceRegistrationViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var capturedImages: [UIImage] = []
    @Published var currentStep = 0
    @Published var isProcessing = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var registrationComplete = false
    @Published var faceDetectionError: Bool = false
    
    private let faceAnalyzer = FaceAnalyzer()
    private let databaseService = DatabaseService()
    private let imageProcessor = ImageProcessor()
    
    var currentPosition: String {
        guard currentStep < FacePosition.all.count else { return FacePosition.all.last ?? FacePosition.center }
        return FacePosition.all[currentStep]
    }
    
    var currentInstruction: String {
        FacePosition.instructions[currentPosition] ?? ""
    }
    
    var isComplete: Bool {
        capturedImages.count >= FacePosition.all.count
    }
    
    var progressPercentage: Double {
        Double(capturedImages.count) / Double(FacePosition.all.count)
    }
    
    func handleImageSelection() {
        guard let item = selectedImages.first else { return }
        
        item.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self?.processSelectedImage(image)
                    }
                case .failure(let error):
                    self?.showAlert("Failed to load image: \(error.localizedDescription)")
                }
                self?.selectedImages.removeAll()
            }
        }
    }
    
    private func processSelectedImage(_ image: UIImage) {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Process image (resize and normalize)
            let processedImage = self.imageProcessor.prepareImageForAnalysis(image)
            
            // Detect faces
            self.faceAnalyzer.detectFaces(in: processedImage) { results in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    if results.isEmpty {
                        self.faceDetectionError = true
                        self.showAlert("No faces detected. Please ensure the face is clear and occupies enough of the frame.")
                    } else {
                        self.faceDetectionError = false
                        self.addCapturedImage(processedImage)
                    }
                }
            }
        }
    }
    
    func addCapturedImage(_ image: UIImage) {
        guard capturedImages.count < FacePosition.all.count else {
            showAlert("You have already taken all the required photos.")
            return
        }
        
        capturedImages.append(image)
        
        if !isComplete {
            currentStep = min(currentStep + 1, FacePosition.all.count - 1)
        }
    }
    
    func nextStep() {
        currentStep = min(currentStep + 1, FacePosition.all.count - 1)
    }
    
    func previousStep() {
        currentStep = max(currentStep - 1, 0)
    }
    
    func completeRegistration(context: ModelContext) {
        guard !name.isEmpty else {
            showAlert("Name cannot be empty.")
            return
        }
        
        guard isComplete else {
            showAlert("Please complete all face positions.")
            return
        }
        
        isProcessing = true
        
        // Process all images to get descriptors
        var allDescriptors: [Data] = []  // Changed to store Data instead of [Float]
        let dispatchGroup = DispatchGroup()
        
        for image in capturedImages {
            dispatchGroup.enter()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    dispatchGroup.leave()
                    return
                }
                
                self.faceAnalyzer.extractFaceDescriptor(from: image) { descriptorData in
                    if let descriptorData = descriptorData {
                        allDescriptors.append(descriptorData)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            guard !allDescriptors.isEmpty else {
                self.showAlert("Failed to extract face features.")
                self.isProcessing = false
                return
            }
            
            // Create average descriptor from Data objects
            guard let averageDescriptor = self.createAverageDescriptor(from: allDescriptors) else {
                self.showAlert("Failed to create face descriptor.")
                self.isProcessing = false
                return
            }
            
            // Compress and save the first image as reference
            guard let imageData = self.imageProcessor.compressImage(self.capturedImages.first) else {
                self.showAlert("Failed to process image.")
                self.isProcessing = false
                return
            }
            
            // Create and save registered face
            let registeredFace = RegisteredFace(
                name: self.name,
                imageData: imageData,
                faceDescriptor: averageDescriptor,
                facePositions: FacePosition.all
            )
            
            self.databaseService.saveFace(registeredFace, to: context)
            self.registrationComplete = true
            self.isProcessing = false
            self.showAlert("Registration successful! The face has been saved to the database.")
        }
    }

    private func createAverageDescriptor(from descriptors: [Data]) -> Data? {
        guard !descriptors.isEmpty else { return nil }
        
        // Convert all descriptors to [Float] arrays
        var floatArrays: [[Float]] = []
        for descriptor in descriptors {
            let floatArray = descriptor.withUnsafeBytes {
                Array($0.bindMemory(to: Float.self))
            }
            floatArrays.append(floatArray)
        }
        
        // Calculate average (simple implementation using first descriptor)
        // For better results, implement proper averaging
        return descriptors.first
    }
    

    func reset() {
        name = ""
        selectedImages.removeAll()
        capturedImages.removeAll()
        currentStep = 0
        isProcessing = false
        registrationComplete = false
        faceDetectionError = false
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}
