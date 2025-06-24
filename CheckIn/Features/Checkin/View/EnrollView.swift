//
//  EnrollView.swift
//  CheckIn
//
//  Created by Akmal Ariq on 24/06/25.
//

import SwiftUI

import SwiftUI

struct EnrollView: View {
    @State private var name = ""
    @State private var leaveCount = 1
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @Environment(AttendanceViewModel.self) private var viewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Stepper(value: $leaveCount, in: 0...30) {
                        Text("Leave Count (Cuti): \(leaveCount)")
                    }
                }
                
                Section(header: Text("Photo")) {
                    if let image = capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Selfie")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    if capturedImage != nil {
                        Button("Retake Photo") {
                            showingCamera = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button(action: enrollPerson) {
                        Text("Enroll Person")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty || capturedImage == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(name.isEmpty || capturedImage == nil)
                }
            }
            .navigationTitle("Enroll Person")
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $capturedImage)
            }
            .alert("Enrollment", isPresented: .constant(viewModel.showingAlert)) {
                Button("OK") {
                    viewModel.showingAlert = false
                }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
    
    private func enrollPerson() {
        guard !name.isEmpty, let image = capturedImage else { return }
        
        let imageData = image.jpegData(compressionQuality: 0.8)
        viewModel.enrollPerson(name: name, leaveCount: leaveCount, photoData: imageData)
        
        // Reset form
        name = ""
        leaveCount = 1
        capturedImage = nil
    }
}
