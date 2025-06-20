//
//  IdentifyView.swift
//  checkin-app
//
//  Created by Akmal Ariq on 17/06/25.
//


// Views/Screens/IdentifyView.swift
import SwiftUI

struct LocationView: View {
    @StateObject private var location = Location()
    @State private var showingLocationHelp = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with icon and description
                headerSection
                
                // Map visualization
                mapSection
                    .padding(.vertical, 8)
                
                // Action button
                detectLocationButton
                
                // Location details (appears after detection)
                if let location = location.currentLocation {
                    locationDetailsSection
                }
                
                // Privacy information
                privacySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Identify Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingLocationHelp.toggle() }) {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .sheet(isPresented: $showingLocationHelp) {
            locationHelpSheet
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            Text("Verify Your Location")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("For accurate identification, we need to confirm your current location. Your location data is used only for verification and is not stored.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var mapSection: some View {
        VStack(spacing: 0) {
            LocationMapView(location: location)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemFill), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            if location.currentLocation == nil {
                Text("Location not yet detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
    
    private var detectLocationButton: some View {
        Button(action: {
            HapticFeedback.selectionTrigger()
            location.requestLocation()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                Text(location.currentLocation == nil ? "Detect My Location" : "Update Location")
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(location.statusMessage == "Detecting location...")
        .overlay(
            Group {
                if location.statusMessage == "Detecting location..." {
                    ProgressView()
                        .tint(.white)
                }
            }
        )
    }
    
    private var locationDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Location Verified")
                    .font(.headline)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                DetailIdentifyRow(icon: "mappin.and.ellipse",
                         title: "Coordinates",
                         value: "\(location.currentLocation?.coordinate.latitude.formatted() ?? ""), \(location.currentLocation?.coordinate.longitude.formatted() ?? "")")
                
                DetailIdentifyRow(icon: "clock",
                         title: "Time",
                         value: location.currentLocation?.timestamp.formatted(date: .omitted, time: .shortened) ?? "")
                
                DetailIdentifyRow(icon: "speedometer",
                         title: "Accuracy",
                         value: "±\(Int(location.currentLocation?.horizontalAccuracy ?? 0)) meters")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy Information")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Your location is used only for verification purposes. We don't store your location data after the verification process is complete.")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.top, 8)
    }
    
    private var locationHelpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About Location Verification")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Location verification helps ensure the accuracy of your identification. Here's what you should know:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    InfoPoint(icon: "location.fill",
                             title: "Why we need your location",
                             description: "This helps confirm your physical presence for secure identification.")
                    
                    InfoPoint(icon: "lock.fill",
                             title: "Your privacy is protected",
                             description: "We only use your location temporarily and don't store it after verification.")
                    
                    InfoPoint(icon: "wifi",
                             title: "Better accuracy with Wi-Fi",
                             description: "For best results, enable Wi-Fi in your device settings even if you're not connected to a network.")
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingLocationHelp = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Helper Views

private struct DetailIdentifyRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundColor(.primary)
        }
    }
}

private struct InfoPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func selectionTrigger() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

struct IdentifyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LocationView()
        }
    }
}
