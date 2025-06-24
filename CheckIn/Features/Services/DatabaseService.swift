//
//  DatabaseService.swift
//  checkin-app
//
//  Created by Darmawan on 18/06/25.
//

import SwiftData
import SwiftUI

class DatabaseService: ObservableObject {
    func saveFace(_ face: RegisteredFace, to context: ModelContext) {
        context.insert(face)
        try? context.save()
    }
    
    func deleteFace(_ face: RegisteredFace, from context: ModelContext) {
        context.delete(face)
        try? context.save()
    }
    
    func getAllFaces(from context: ModelContext) -> [RegisteredFace] {
        let descriptor = FetchDescriptor<RegisteredFace>(
            sortBy: [SortDescriptor(\.registrationDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}

