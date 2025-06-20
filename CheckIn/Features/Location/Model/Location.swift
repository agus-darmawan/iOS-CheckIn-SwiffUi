//
//  Location.swift
//  checkin-app
//
//  Created by Akmal Ariq on 19/06/25.
//

import SwiftUI
import CoreLocation
import MapKit

class Location: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var statusMessage = "Location not detected"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        statusMessage = "Detecting location..."
    }
}

extension Location: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        statusMessage = "Location updated"
        
        withAnimation {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: 1000,
                    heading: 0,
                    pitch: 0
                )
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = "Error: \(error.localizedDescription)"
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied:
            statusMessage = "Location access denied"
        case .notDetermined:
            statusMessage = "Location access not determined"
        case .restricted:
            statusMessage = "Location access restricted"
        @unknown default:
            statusMessage = "Unknown authorization status"
        }
    }
}
