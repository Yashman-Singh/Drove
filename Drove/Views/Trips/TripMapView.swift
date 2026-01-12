//
//  TripMapView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct TripMapView: View {
    let trip: Trip
    
    @State private var cameraPosition: MapCameraPosition
    
    init(trip: Trip) {
        self.trip = trip
        _cameraPosition = State(initialValue: .automatic)
    }
    
    var body: some View {
        Map(position: $cameraPosition) {
            // Route polyline
            if let routeCoordinates = getRouteCoordinates(), routeCoordinates.count > 1 {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(.blue, lineWidth: 4)
            }
            
            // Start marker
            Marker(
                "Start",
                coordinate: CLLocationCoordinate2D(
                    latitude: trip.startLatitude,
                    longitude: trip.startLongitude
                )
            )
            .tint(.green)
            
            // End marker (if available)
            if let endLat = trip.endLatitude, let endLng = trip.endLongitude {
                Marker(
                    "End",
                    coordinate: CLLocationCoordinate2D(
                        latitude: endLat,
                        longitude: endLng
                    )
                )
                .tint(.red)
            }
        }
        .mapStyle(.standard)
        .onAppear {
            updateCameraPosition()
        }
    }
    
    private func getRouteCoordinates() -> [CLLocationCoordinate2D]? {
        let coordinates = trip.getRouteCoordinates()
        return coordinates.isEmpty ? nil : coordinates
    }
    
    private func updateCameraPosition() {
        let coordinates = getRouteCoordinates() ?? []
        
        // If we have route coordinates, fit bounds to show entire route
        if coordinates.count > 1 {
            var minLat = coordinates[0].latitude
            var maxLat = coordinates[0].latitude
            var minLng = coordinates[0].longitude
            var maxLng = coordinates[0].longitude
            
            for coord in coordinates {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLng = min(minLng, coord.longitude)
                maxLng = max(maxLng, coord.longitude)
            }
            
            // Add padding
            let latPadding = (maxLat - minLat) * 0.2
            let lngPadding = (maxLng - minLng) * 0.2
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLng + maxLng) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) + latPadding * 2,
                longitudeDelta: (maxLng - minLng) + lngPadding * 2
            )
            
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        } else if let endLat = trip.endLatitude, let endLng = trip.endLongitude {
            // Show both start and end if we have them
            let startCoord = CLLocationCoordinate2D(
                latitude: trip.startLatitude,
                longitude: trip.startLongitude
            )
            let endCoord = CLLocationCoordinate2D(
                latitude: endLat,
                longitude: endLng
            )
            
            let minLat = min(startCoord.latitude, endCoord.latitude)
            let maxLat = max(startCoord.latitude, endCoord.latitude)
            let minLng = min(startCoord.longitude, endCoord.longitude)
            let maxLng = max(startCoord.longitude, endCoord.longitude)
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLng + maxLng) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
                longitudeDelta: max((maxLng - minLng) * 1.5, 0.01)
            )
            
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        } else {
            // Just show start location
            let center = CLLocationCoordinate2D(
                latitude: trip.startLatitude,
                longitude: trip.startLongitude
            )
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: center,
                    distance: 1000
                )
            )
        }
    }
}

#Preview {
    let trip = Trip(startLatitude: 37.7749, startLongitude: -122.4194)
    trip.endLatitude = 34.0522
    trip.endLongitude = -118.2437
    
    var coords: [CLLocationCoordinate2D] = []
    coords.append(CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
    coords.append(CLLocationCoordinate2D(latitude: 37.5, longitude: -121.0))
    coords.append(CLLocationCoordinate2D(latitude: 36.0, longitude: -119.0))
    coords.append(CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437))
    trip.setRouteCoordinates(coords)
    
    return TripMapView(trip: trip)
        .frame(height: 300)
}
