//
//  Location.swift
//  checkin-app
//
//  Created by Akmal Ariq on 19/06/25.
//
// Views/Components/LocationMapView.swift
import SwiftUI
import MapKit

struct LocationMapView: View {
    @ObservedObject var location: Location
    
    var body: some View {
        VStack(spacing: 8) {
            if let location = location.currentLocation {
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
