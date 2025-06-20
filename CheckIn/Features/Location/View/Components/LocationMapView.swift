// Views/Components/LocationMapView.swift
import SwiftUI
import MapKit

struct LocationMapView: View {
    @ObservedObject var location: Location
    
    var body: some View {
        VStack(spacing: 8) {
            if let location = location.currentLocation {
                Text("Current Location")
                    .font(.headline)
                Text("Latitude: \(location.coordinate.latitude, specifier: "%.6f")")
                Text("Longitude: \(location.coordinate.longitude, specifier: "%.6f")")
                
                Map(position: $location.cameraPosition) {
                    UserAnnotation()
                }
                .mapStyle(.standard)
                .mapControls {
                    MapUserLocationButton()
                }
                .frame(height: 300)
                .cornerRadius(10)
            } else {
                Text(location.statusMessage)
                    .padding()
                
                Map(position: .constant(.automatic))
                    .mapStyle(.standard)
                    .frame(height: 300)
                    .cornerRadius(10)
                    .opacity(0.5)
            }
        }
    }
}
