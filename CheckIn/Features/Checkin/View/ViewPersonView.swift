//
//  ViewPersonView.swift
//  CheckIn
//
//  Created by Akmal Ariq on 24/06/25.
//

import SwiftUI

struct ViewPersonView: View {
    @Environment(AttendanceViewModel.self) private var viewModel
    @State private var selectedPerson: Person?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.people, id: \.id) { person in
                    PersonRowView(person: person)
                        .onTapGesture {
                            selectedPerson = person
                        }
                }
            }
            .navigationTitle("All Persons")
            .onAppear {
                viewModel.fetchPeople()
                viewModel.fetchCheckInLogs()
            }
            .sheet(item: $selectedPerson) { person in
                PersonDetailView(person: person)
            }
        }
    }
}

struct PersonRowView: View {
    let person: Person
    
    var body: some View {
        HStack {
            // Person Photo
            if let photoData = person.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.headline)
                Text("ID: \(person.id.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Leave Count: \(person.leaveCount)")
                    .font(.caption)
                    .foregroundColor(person.leaveCount > 0 ? .green : .red)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(person.checkInLogs.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Records")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PersonDetailView: View {
    let person: Person
    @Environment(\.presentationMode) var presentationMode
    @Environment(AttendanceViewModel.self) private var viewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Person Info Header
                    HStack {
                        if let photoData = person.photoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(person.name)
                                .font(.title)
                                .fontWeight(.bold)
                            Text("ID: \(person.id.uuidString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Leave Count: \(person.leaveCount)")
                                .font(.title3)
                                .foregroundColor(person.leaveCount > 0 ? .green : .red)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Check-in Logs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check-in/Check-out History")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if person.checkInLogs.isEmpty {
                            Text("No check-in records found")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(person.checkInLogs.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { log in
                                CheckInLogRowView(log: log)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Person Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct CheckInLogRowView: View {
    let log: CheckInLog
    @Environment(AttendanceViewModel.self) private var viewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(log.type.rawValue)
                        .font(.headline)
                        .foregroundColor(log.type == .checkIn ? .blue : .orange)
                    
                    if !log.isOnTime {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Text(viewModel.formatDate(log.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !log.isOnTime {
                    Text("Late - Leave count deducted")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if let photoData = log.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
