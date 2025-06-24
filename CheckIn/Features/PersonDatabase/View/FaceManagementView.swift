//
//  FaceManagementView.swift
//  checkin-app
//
//  Created by Darmawan on 18/06/25.
//

import SwiftUI
import SwiftData

struct FaceManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FaceManagementViewModel()
    @Query(sort: \RegisteredFace.registrationDate, order: .reverse) private var registeredFaces: [RegisteredFace]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                // Face List
                let filteredFaces = viewModel.filteredFaces(registeredFaces)
                
                if filteredFaces.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(registeredFaces.isEmpty ? "No faces registered yet" : "No search results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if registeredFaces.isEmpty {
                            Text("Start by registering faces in the Registration tab")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredFaces) { face in
                            FaceRowView(face: face) {
                                viewModel.confirmDelete(face)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Face Database")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete Face", isPresented: $viewModel.showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let face = viewModel.faceToDelete {
                        viewModel.deleteFace(face, context: modelContext)
                    }
                }
            } message: {
                if let face = viewModel.faceToDelete {
                    Text("Are you sure you want to delete \(face.name) from the database?")
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search by name...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FaceRowView: View {
    let face: RegisteredFace
    let onDelete: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Face Image
            if let image = face.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            // Face Info - Tap to view details
            Button(action: {
                showingDetail = true
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(face.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Registered: \(face.registrationDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                        Text("\(face.facePositions.count) positions")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                .contentShape(Rectangle()) // Ensure the entire area is tappable
            }
            .buttonStyle(PlainButtonStyle()) // Remove highlight effect
            
            Spacer()
            
            // Actions - Delete button separately
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
                    .padding(8) // Make the tap area larger
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingDetail) {
            FaceDetailView(face: face)
        }
    }
}

struct FaceDetailView: View {
    let face: RegisteredFace
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Face Image
                    if let image = face.uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                    }
                    
                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(title: "Name", value: face.name)
                        InfoRow(title: "ID", value: face.id.uuidString)
                        InfoRow(title: "Registration Date", value: face.registrationDate, formatter: dateFormatter)
                        InfoRow(title: "Number of Positions", value: "\(face.facePositions.count)")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Face Positions
                    if !face.facePositions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Registered Face Positions")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(face.facePositions, id: \.self) { position in
                                    HStack {
                                        Image(systemName: positionIcon(for: position))
                                            .foregroundColor(.blue)
                                        Text(FacePosition.instructions[position] ?? position)
                                            .font(.caption)
                                    }
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Technical Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technical Information")
                            .font(.headline)
                        
                        InfoRow(title: "Descriptor Size", value: "\(face.faceDescriptor.count) bytes")
                        InfoRow(title: "Image Size", value: "\(face.imageData.count) bytes")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Face Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func positionIcon(for position: String) -> String {
        switch position {
        case FacePosition.center: return "face.smiling"
        case FacePosition.left: return "arrow.left"
        case FacePosition.right: return "arrow.right"
        case FacePosition.up: return "arrow.up"
        case FacePosition.down: return "arrow.down"
        default: return "questionmark"
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
    }
    
    init(title: String, value: Date, formatter: DateFormatter) {
        self.title = title
        self.value = formatter.string(from: value)
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()
