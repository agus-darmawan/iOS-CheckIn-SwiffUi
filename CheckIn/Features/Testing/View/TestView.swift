//
//  TestingView.swift
//  CheckInApp
//
//  Created by Darmawan on 25/06/25.
//


import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

struct TestView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TestViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    TestHeaderView()
                    
                    // Test Categories
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        TestCategoryCard(
                            icon: "camera.viewfinder",
                            title: "Live Detection Test",
                            description: "Test real-time face detection",
                            color: .blue
                        ) {
                            showingCamera = true
                        }
                        
                        TestCategoryCard(
                            icon: "photo.on.rectangle",
                            title: "Image Analysis",
                            description: "Analyze image quality",
                            color: .green
                        ) {
                            showingImagePicker = true
                        }
                        
                        TestCategoryCard(
                            icon: "person.3.fill",
                            title: "Database Test",
                            description: "Test database operations",
                            color: .orange
                        ) {
                            viewModel.testDatabaseOperations(context: modelContext)
                        }
                        
                        TestCategoryCard(
                            icon: "brain.head.profile",
                            title: "FaceNet Model",
                            description: "Test face recognition",
                            color: .purple
                        ) {
                            viewModel.testFaceNetModel()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Test Results Section
                    if !viewModel.testResults.isEmpty {
                        TestResultsSection(results: viewModel.testResults)
                    }
                    
                    // Image Analysis Section
                    if let selectedImage = viewModel.selectedImage {
                        ImageAnalysisSection(
                            image: selectedImage,
                            analysisResult: viewModel.imageAnalysisResult
                        )
                    }
                    
                    // Debug Info Section
                    if viewModel.showDebugInfo {
                        DebugInfoSection(debugInfo: viewModel.debugInfo)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button("Clear Results") {
                                viewModel.clearResults()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            Button("Export Logs") {
                                viewModel.exportDebugLogs()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        
                        Toggle("Show Debug Info", isOn: $viewModel.showDebugInfo)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Testing")
            .navigationBarTitleDisplayMode(.large)
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $viewModel.selectedImageItem,
                matching: .images
            )
            .sheet(isPresented: $showingCamera) {
                TestCameraView { image in
                    viewModel.analyzeTestImage(image)
                    showingCamera = false
                }
            }
            .onChange(of: viewModel.selectedImageItem) { _, _ in
                viewModel.loadSelectedImage()
            }
            .alert("Test Result", isPresented: $viewModel.showingAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

// Supporting Views
struct TestHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flask.fill")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("Testing & Debugging")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Test face detection, liveness, and quality analysis")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct TestCategoryCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TestResultsSection: View {
    let results: [TestResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(results) { result in
                    TestResultCard(result: result)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TestResultCard: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.isSuccess ? .green : .red)
                
                Text(result.testName)
                    .font(.headline)
                
                Spacer()
                
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !result.details.isEmpty {
                DisclosureGroup("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.details, id: \.self) { detail in
                            Text("• \(detail)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ImageAnalysisSection: View {
    let image: UIImage
    let analysisResult: ImageAnalysisResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Analysis")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if let result = analysisResult {
                    VStack(alignment: .leading, spacing: 6) {
                        AnalysisMetric(title: "Quality", value: result.qualityScore, color: qualityColor(result.qualityScore))
                        AnalysisMetric(title: "Sharpness", value: result.sharpness, color: qualityColor(result.sharpness))
                        AnalysisMetric(title: "Brightness", value: result.brightness, color: brightnessColor(result.brightness))
                        AnalysisMetric(title: "Liveness Potential", value: result.livenessPotential, color: qualityColor(result.livenessPotential))
                    }
                } else {
                    Text("Analyzing...")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if let result = analysisResult, !result.issues.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Issues Found:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(result.issues, id: \.self) { issue in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(issue)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private func qualityColor(_ value: Float) -> Color {
        switch value {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
    
    private func brightnessColor(_ value: Float) -> Color {
        if value >= 0.3 && value <= 0.7 {
            return .green
        } else {
            return .orange
        }
    }
}

struct AnalysisMetric: View {
    let title: String
    let value: Float
    let color: Color
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(String(format: "%.1f%%", value * 100))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct DebugInfoSection: View {
    let debugInfo: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug Information")
                .font(.headline)
                .padding(.horizontal)
            
            DisclosureGroup("System Info") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(debugInfo.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key + ":")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(describing: debugInfo[key] ?? "N/A"))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// Test Camera View
struct TestCameraView: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage) -> Void
        
        init(completion: @escaping (UIImage) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                completion(image.fixedOrientation())
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
