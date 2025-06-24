//
//  CheckInView.swift
//  CheckIn
//
//  Created by Akmal Ariq on 24/06/25.
//

import SwiftUI

struct CheckInView: View {
    @State private var selectedPersonId: UUID?
    @State private var capturedImage: UIImage?
    @State private var showingCamera = false
    @State private var checkInType: CheckInType = .checkIn
    @Environment(AttendanceViewModel.self) private var viewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Check In/Out Information")) {
                    Picker("Action", selection: $checkInType) {
                        ForEach(CheckInType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Select Person", selection: $selectedPersonId) {
                        Text("Select a person").tag(nil as UUID?)
                        ForEach(viewModel.people, id: \.id) { person in
                            Text(person.name).tag(person.id as UUID?)
                        }
                    }
                }
                
                Section(header: Text("Current Time Info")) {
                    HStack {
                        Text("Current Time:")
                        Spacer()
                        Text(formatCurrentTime())
                            .fontWeight(.semibold)
                    }
                    
                    if checkInType == .checkIn {
                        HStack {
                            Text("Check-in Window:")
                            Spacer()
                            Text("6:00 AM - 8:15 AM")
                                .foregroundColor(viewModel.isValidCheckInTime() ? .green : .red)
                        }
                    } else {
                        HStack {
                            Text("Check-out Window:")
                            Spacer()
                            Text("12:00 PM - 6:00 PM")
                                .foregroundColor(viewModel.isValidCheckOutTime() ? .green : .red)
                        }
                    }
                }
                
                Section(header: Text("Photo Verification")) {
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
                                Text("Take Photo")
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
                    Button(action: performCheckInOut) {
                        Text(checkInType.rawValue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canPerformAction() ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!canPerformAction())
                    
                    if let selectedPersonId = selectedPersonId,
                       let person = viewModel.people.first(where: { $0.id == selectedPersonId }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Person: \(person.name)")
                                .font(.caption)
                            Text("Current Leave Count: \(person.leaveCount)")
                                .font(.caption)
                                .foregroundColor(person.leaveCount > 0 ? .green : .red)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Check In/Out")
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $capturedImage)
            }
            .alert("Check In/Out", isPresented: .constant(viewModel.showingAlert)) {
                Button("OK") {
                    viewModel.showingAlert = false
                    // Reset form after successful action
                    if viewModel.alertMessage.contains("successful") {
                        resetForm()
                    }
                }
            } message: {
                Text(viewModel.alertMessage)
            }
            .onAppear {
                viewModel.fetchPeople()
            }
        }
    }
    
    private func canPerformAction() -> Bool {
        return selectedPersonId != nil && capturedImage != nil
    }
    
    private func performCheckInOut() {
        guard let personId = selectedPersonId,
              let image = capturedImage else { return }
        
        let imageData = image.jpegData(compressionQuality: 0.8)
        
        switch checkInType {
        case .checkIn:
            viewModel.checkIn(personId: personId, photoData: imageData)
        case .checkOut:
            viewModel.checkOut(personId: personId, photoData: imageData)
        }
    }
    
    private func resetForm() {
        selectedPersonId = nil
        capturedImage = nil
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
