//
//  FaceManagementViewModel.swift
//  checkin-app
//
//  Created by Darmawan on 18/06/25.
//


import SwiftUI
import SwiftData

class FaceManagementViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var showingDeleteAlert = false
    @Published var faceToDelete: RegisteredFace?
    
    private let databaseService = DatabaseService()
    
    func filteredFaces(_ faces: [RegisteredFace]) -> [RegisteredFace] {
        if searchText.isEmpty {
            return faces
        }
        return faces.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    func deleteFace(_ face: RegisteredFace, context: ModelContext) {
        databaseService.deleteFace(face, from: context)
    }
    
    func confirmDelete(_ face: RegisteredFace) {
        faceToDelete = face
        showingDeleteAlert = true
    }
}
