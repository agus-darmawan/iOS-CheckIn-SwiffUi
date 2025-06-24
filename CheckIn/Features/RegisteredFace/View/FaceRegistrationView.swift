//
//  FaceRegistrationView.swift
//  CheckIn
//
//  Created by Darmawan on 25/06/25.
//


import SwiftUI
import SwiftData
import PhotosUI

struct FaceRegistrationView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FaceRegistrationViewModel()
    @State private var showingCamera = false
    @State private var cameraError: CameraError?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Face Registration")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Register a new face by taking photos from various positions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.headline)
                        
                        TextField("Enter your full name", text: $viewModel.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal)
                    
                    if !viewModel.name.isEmpty {
                        // Progress Indicator
                        VStack(spacing: 12) {
                            HStack {
                                Text("Photo Progress")
                                    .font(.headline)
                                Spacer()
                                Text("\(viewModel.capturedImages.count)/\(FacePosition.all.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: Double(viewModel.capturedImages.count), total: Double(FacePosition.all.count))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        }
                        .padding(.horizontal)
                        
                        // Current Step Instructions
                        if !viewModel.isComplete {
                            VStack(spacing: 12) {
                                Text("Step \(viewModel.currentStep + 1) of \(FacePosition.all.count)")
                                    .font(.headline)
                                
                                Text(viewModel.currentInstruction)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                // Position Icon
                                Image(systemName: positionIcon(for: viewModel.currentPosition))
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Captured Images Grid
                        if !viewModel.capturedImages.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Captured Photos")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) { index, image in
                                        VStack(spacing: 4) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.green, lineWidth: 2)
                                                )
                                            
                                            Text(FacePosition.all[index])
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if !viewModel.isComplete {
                                // Photo Capture Options
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if CameraView.isCameraAvailable {
                                            showingCamera = true
                                        } else {
                                            cameraError = .unavailable
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                            Text("Camera")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                    
                                    PhotosPicker(
                                        selection: $viewModel.selectedImages,
                                        maxSelectionCount: 1,
                                        matching: .images
                                    ) {
                                        HStack {
                                            Image(systemName: "photo.fill")
                                            Text("Gallery")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Navigation Buttons
                                if !viewModel.capturedImages.isEmpty {
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            viewModel.previousStep()
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.left")
                                                Text("Previous")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundColor(.primary)
                                            .cornerRadius(10)
                                        }
                                        .disabled(viewModel.currentStep == 0)
                                        
                                        Button(action: {
                                            viewModel.nextStep()
                                        }) {
                                            HStack {
                                                Text("Next")
                                                Image(systemName: "arrow.right")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                        }
                                        .disabled(viewModel.currentStep >= viewModel.capturedImages.count)
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                // Complete Registration
                                Button(action: {
                                    viewModel.completeRegistration(context: modelContext)
                                }) {
                                    HStack {
                                        if viewModel.isProcessing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                        Text(viewModel.isProcessing ? "Processing..." : "Complete Registration")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.isProcessing ? Color.gray : Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(viewModel.isProcessing)
                                .padding(.horizontal)
                            }
                            
                            // Reset Button
                            if !viewModel.capturedImages.isEmpty {
                                Button(action: {
                                    viewModel.reset()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Start Over")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Registration")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    viewModel.addCapturedImage(image)
                    showingCamera = false
                }
                .ignoresSafeArea()
            }
            .onChange(of: viewModel.selectedImages) { _, _ in
                viewModel.handleImageSelection()
            }
            .alert("Registration", isPresented: $viewModel.showingAlert) {
                if viewModel.registrationComplete {
                    Button("Start New") {
                        viewModel.reset()
                    }
                    Button("OK") { }
                } else {
                    Button("OK") { }
                }
            } message: {
                Text(viewModel.alertMessage)
            }
            .alert(item: $cameraError) { error in
                Alert(
                    title: Text("Camera Error"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func positionIcon(for position: String) -> String {
        switch position {
        case FacePosition.center: return "face.smiling"
        case FacePosition.left: return "arrow.left.circle"
        case FacePosition.right: return "arrow.right.circle"
        case FacePosition.up: return "arrow.up.circle"
        case FacePosition.down: return "arrow.down.circle"
        default: return "questionmark.circle"
        }
    }
}

enum CameraError: Identifiable, LocalizedError {
    case unavailable
    case configurationFailed
    
    var id: String { localizedDescription }
    
    var localizedDescription: String {
        switch self {
        case .unavailable: return "Camera is not available on this device"
        case .configurationFailed: return "Failed to configure camera"
        }
    }
}
