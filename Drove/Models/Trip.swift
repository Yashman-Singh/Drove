//
//  Trip.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Trip {
    // MARK: - Identifiers
    var id: UUID
    
    // MARK: - Timestamps
    var startTime: Date
    var endTime: Date?
    
    // MARK: - Start Location
    var startLatitude: Double
    var startLongitude: Double
    var startAddress: String?
    var startCity: String?
    var startState: String?
    var startCountry: String?
    
    // MARK: - End Location
    var endLatitude: Double?
    var endLongitude: Double?
    var endAddress: String?
    var endCity: String?
    var endState: String?
    var endCountry: String?
    
    // MARK: - Trip Data
    var distanceMeters: Double
    var routeCoordinates: Data?
    
    // MARK: - Metadata
    var category: String
    var tags: [String]
    var notes: String?
    var isFavorite: Bool
    var isHidden: Bool
    
    // MARK: - Relationships
    var vehicle: Vehicle?
    
    // MARK: - Computed Properties
    var isInProgress: Bool {
        endTime == nil
    }
    
    var durationSeconds: TimeInterval {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return end.timeIntervalSince(startTime)
    }
    
    var distanceMiles: Double {
        distanceMeters * 0.000621371
    }
    
    var distanceKilometers: Double {
        distanceMeters / 1000
    }
    
    // MARK: - Initialization
    init(startTime: Date = Date(),
         startLatitude: Double,
         startLongitude: Double) {
        self.id = UUID()
        self.startTime = startTime
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.distanceMeters = 0
        self.category = TripCategory.other.rawValue
        self.tags = []
        self.isFavorite = false
        self.isHidden = false
    }
}

// MARK: - Route Encoding/Decoding
extension Trip {
    /// Decode route coordinates from stored Data
    func getRouteCoordinates() -> [CLLocationCoordinate2D] {
        guard let data = routeCoordinates else { return [] }
        do {
            let coordinates = try JSONDecoder().decode([[Double]].self, from: data)
            return coordinates.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
        } catch {
            return []
        }
    }
    
    /// Encode and store route coordinates
    func setRouteCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        let array = coordinates.map { [$0.latitude, $0.longitude] }
        routeCoordinates = try? JSONEncoder().encode(array)
    }
    
    /// Append a single coordinate to the route
    func appendRouteCoordinate(_ coordinate: CLLocationCoordinate2D) {
        var coords = getRouteCoordinates()
        coords.append(coordinate)
        setRouteCoordinates(coords)
    }
}

