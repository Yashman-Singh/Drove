//
//  TripsMapView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct TripsMapView: View {
    @Query(filter: #Predicate<Trip> { !$0.isHidden }) private var trips: [Trip]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedYearOption: MapYearOption = .allTime
    
    var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(trips.map { calendar.component(.year, from: $0.startTime) })
        return Array(years).sorted(by: >)
    }
    
    var yearOptions: [MapYearOption] {
        var options: [MapYearOption] = [.allTime]
        options.append(contentsOf: availableYears.map { .year($0) })
        // Add "This Month" at the end
        options.append(.thisMonth)
        return options
    }
    
    var filteredTrips: [Trip] {
        switch selectedYearOption {
        case .allTime:
            return trips
        case .year(let year):
            let calendar = Calendar.current
            return trips.filter { calendar.component(.year, from: $0.startTime) == year }
        case .thisMonth:
            let calendar = Calendar.current
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
                return trips
            }
            return trips.filter { $0.startTime >= startOfMonth }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map
            Map(position: $cameraPosition) {
                ForEach(filteredTrips) { trip in
                    // Route polyline - make it thicker and more visible
                    let routeCoordinates = trip.getRouteCoordinates()
                    if routeCoordinates.count > 1 {
                        MapPolyline(coordinates: routeCoordinates)
                            .stroke(
                                .linearGradient(
                                    Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 6
                            )
                    } else if let endLat = trip.endLatitude, let endLng = trip.endLongitude {
                        // Fallback: show line from start to end if no route data
                        MapPolyline(coordinates: [
                            CLLocationCoordinate2D(latitude: trip.startLatitude, longitude: trip.startLongitude),
                            CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
                        ])
                        .stroke(
                            .linearGradient(
                                Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.6)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 6
                        )
                    }
                    
                    // Start annotation - use custom annotation for better visibility
                    Annotation(
                        trip.startCity ?? trip.startState ?? "Start",
                        coordinate: CLLocationCoordinate2D(
                            latitude: trip.startLatitude,
                            longitude: trip.startLongitude
                        ),
                        anchor: .center
                    ) {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                            .shadow(radius: 3)
                    }
                    
                    // End annotation
                    if let endLat = trip.endLatitude, let endLng = trip.endLongitude {
                        Annotation(
                            trip.endCity ?? trip.endState ?? "End",
                            coordinate: CLLocationCoordinate2D(
                                latitude: endLat,
                                longitude: endLng
                            ),
                            anchor: .center
                        ) {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                                .shadow(radius: 3)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 400)
            .onAppear {
                updateCameraPosition()
            }
            .onChange(of: selectedYearOption) { _, _ in
                updateCameraPosition()
            }
            
            // Filter Bar - horizontally scrollable
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(yearOptions) { option in
                        Button {
                            selectedYearOption = option
                        } label: {
                            Text(option.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedYearOption.id == option.id ? Color.accentColor : Color(.systemGray5))
                                .foregroundColor(selectedYearOption.id == option.id ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, AppConstants.standardPadding)
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cornerRadius)
        .shadow(radius: AppConstants.cardShadowRadius)
    }
    
    private func updateCameraPosition() {
        guard !filteredTrips.isEmpty else {
            cameraPosition = .automatic
            return
        }
        
        // Collect all coordinates
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        for trip in filteredTrips {
            allCoordinates.append(CLLocationCoordinate2D(
                latitude: trip.startLatitude,
                longitude: trip.startLongitude
            ))
            
            if let endLat = trip.endLatitude, let endLng = trip.endLongitude {
                allCoordinates.append(CLLocationCoordinate2D(
                    latitude: endLat,
                    longitude: endLng
                ))
            }
            
            // Add route coordinates if available
            allCoordinates.append(contentsOf: trip.getRouteCoordinates())
        }
        
        guard !allCoordinates.isEmpty else {
            cameraPosition = .automatic
            return
        }
        
        // Calculate bounds
        var minLat = allCoordinates[0].latitude
        var maxLat = allCoordinates[0].latitude
        var minLng = allCoordinates[0].longitude
        var maxLng = allCoordinates[0].longitude
        
        for coord in allCoordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLng = min(minLng, coord.longitude)
            maxLng = max(maxLng, coord.longitude)
        }
        
        // Add padding
        let latPadding = max((maxLat - minLat) * 0.2, 0.1)
        let lngPadding = max((maxLng - minLng) * 0.2, 0.1)
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) + latPadding * 2,
            longitudeDelta: (maxLng - minLng) + lngPadding * 2
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

enum MapYearOption: Identifiable, Hashable {
    case allTime
    case year(Int)
    case thisMonth
    
    var id: String {
        switch self {
        case .allTime:
            return "all-time"
        case .year(let year):
            return "\(year)"
        case .thisMonth:
            return "this-month"
        }
    }
    
    var displayName: String {
        switch self {
        case .allTime:
            return "All Time"
        case .year(let year):
            return "\(year)"
        case .thisMonth:
            return "This Month"
        }
    }
}

#Preview {
    TripsMapView()
        .modelContainer(ModelContainerProvider.shared)
        .padding()
}
