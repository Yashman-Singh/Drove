//
//  TripManager.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftData
import CoreLocation
import Observation

@Observable
final class TripManager {
    // MARK: - State
    var activeTrip: Trip?
    var isRecording: Bool { activeTrip != nil }
    
    // MARK: - Dependencies
    private let locationManager: LocationManager
    private let modelContext: ModelContext
    
    // MARK: - Private State
    private var lastMovementTime: Date?
    private var stationaryTimer: Timer?
    
    // MARK: - Trip State Persistence
    // Store active trip ID to survive app termination
    private let activeTripIDKey = "activeTripID"
    
    private var persistedTripID: UUID? {
        get {
            guard let uuidString = UserDefaults.standard.string(forKey: activeTripIDKey) else {
                return nil
            }
            return UUID(uuidString: uuidString)
        }
        set {
            if let uuidString = newValue?.uuidString {
                UserDefaults.standard.set(uuidString, forKey: activeTripIDKey)
            } else {
                UserDefaults.standard.removeObject(forKey: activeTripIDKey)
            }
        }
    }
    
    init(locationManager: LocationManager, modelContext: ModelContext) {
        self.locationManager = locationManager
        self.modelContext = modelContext
        
        // Check for unfinished trip from previous session
        restoreActiveTripIfNeeded()
    }
    
    // MARK: - Trip Restoration
    
    /// Called on init to restore any trip that was in progress when app was killed
    private func restoreActiveTripIfNeeded() {
        guard let tripID = persistedTripID else { return }
        
        // SwiftData predicates can't compare UUIDs directly, so fetch all and filter
        let descriptor = FetchDescriptor<Trip>()
        if let trips = try? modelContext.fetch(descriptor),
           let trip = trips.first(where: { $0.id == tripID }),
           trip.endTime == nil {
            // Found an unfinished trip - restore it
            activeTrip = trip
            
            // Resume location tracking
            locationManager.startTracking { [weak self] newLocation in
                self?.handleLocationUpdate(newLocation)
            }
            startStationaryDetection()
        } else {
            // Trip was finished or not found - clear persisted ID
            persistedTripID = nil
        }
    }
    
    /// Check if there's an interrupted trip that needs user decision
    func hasInterruptedTrip() -> Bool {
        guard let tripID = persistedTripID else { return false }
        
        // SwiftData predicates can't compare UUIDs directly, so fetch all and filter
        let descriptor = FetchDescriptor<Trip>()
        if let trips = try? modelContext.fetch(descriptor),
           let trip = trips.first(where: { $0.id == tripID }) {
            return trip.endTime == nil
        }
        return false
    }
    
    // MARK: - Public Methods
    
    func startTrip(vehicle: Vehicle? = nil) async throws {
        guard activeTrip == nil else {
            throw TripError.tripAlreadyInProgress
        }
        
        // Try to get current location - warm up location manager first if needed
        var location = locationManager.currentLocation
        if location == nil {
            // Try to get an initial location fix
            await locationManager.requestInitialLocation()
            location = locationManager.currentLocation
        }
        
        // If still no location, try one-shot request
        if location == nil {
            location = try await locationManager.getCurrentLocation()
        }
        
        guard let location = location else {
            throw TripError.locationUnavailable
        }
        
        let trip = Trip(
            startLatitude: location.coordinate.latitude,
            startLongitude: location.coordinate.longitude
        )
        
        // Assign vehicle if provided
        trip.vehicle = vehicle
        
        // Reverse geocode start location
        await reverseGeocode(location: location, for: trip, isStart: true)
        
        modelContext.insert(trip)
        activeTrip = trip
        
        // Persist trip ID to survive app termination
        persistedTripID = trip.id
        
        // Persist immediately so App Intents and app UI can see the active trip
        do {
            try modelContext.save()
            print("✅ Trip saved successfully on start. ID: \(trip.id), Distance: \(trip.distanceMeters)m, Hidden: \(trip.isHidden)")
        } catch {
            print("❌ ERROR: Failed to save trip on start: \(error)")
            print("   Trip ID: \(trip.id)")
            print("   Context: \(modelContext)")
            // Remove from context if save failed
            modelContext.delete(trip)
            activeTrip = nil
            persistedTripID = nil
            throw error
        }
        
        // Start location tracking
        locationManager.startTracking { [weak self] newLocation in
            self?.handleLocationUpdate(newLocation)
        }
        
        // Start stationary detection
        startStationaryDetection()
    }
    
    func stopTrip() async throws {
        guard let trip = activeTrip else {
            throw TripError.noTripInProgress
        }
        
        trip.endTime = Date()
        
        if let location = locationManager.currentLocation {
            trip.endLatitude = location.coordinate.latitude
            trip.endLongitude = location.coordinate.longitude
            await reverseGeocode(location: location, for: trip, isStart: false)
        }
        
        // Check if trip meets minimum distance
        if trip.distanceMeters < AppConstants.minimumTripDistanceMeters {
            trip.isHidden = true  // Auto-hide short trips
        }
        
        locationManager.stopTracking()
        stopStationaryDetection()
        
        // Ensure trip is saved before clearing active state
        do {
            try modelContext.save()
            print("✅ Trip saved successfully on stop. ID: \(trip.id), Distance: \(trip.distanceMeters)m (\(trip.distanceMiles.formattedMiles)), Hidden: \(trip.isHidden), EndTime: \(trip.endTime?.description ?? "nil")")
            
            // Verify the trip is actually in the database
            // SwiftData predicates can't compare UUIDs directly, so fetch all and filter
            let verifyDescriptor = FetchDescriptor<Trip>()
            if let trips = try? modelContext.fetch(verifyDescriptor),
               let savedTrip = trips.first(where: { $0.id == trip.id }) {
                print("✅ Verified: Trip exists in database. Distance: \(savedTrip.distanceMeters)m, Hidden: \(savedTrip.isHidden)")
            } else {
                print("⚠️ WARNING: Trip not found in database after save!")
            }
        } catch {
            print("❌ ERROR: Failed to save trip on stop: \(error)")
            print("   Trip ID: \(trip.id)")
            print("   Distance: \(trip.distanceMeters)m")
            print("   Context: \(modelContext)")
            // Don't clear active state if save failed
            throw error
        }
        
        // Clear persisted trip ID
        persistedTripID = nil
        activeTrip = nil
    }
    
    // MARK: - Private Methods
    
    private func handleLocationUpdate(_ location: CLLocation) {
        guard let trip = activeTrip else { return }
        
        // Update distance
        let previousCoordinates = trip.getRouteCoordinates()
        if let lastCoord = previousCoordinates.last {
            let lastLocation = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            trip.distanceMeters += location.distance(from: lastLocation)
        }
        
        // Append to route
        trip.appendRouteCoordinate(location.coordinate)
        
        // Update movement time for stationary detection
        if location.speed > 2.0 { // Moving faster than ~4.5 mph
            lastMovementTime = Date()
        }
    }
    
    private func startStationaryDetection() {
        lastMovementTime = Date()
        stationaryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkStationary()
        }
    }
    
    private func stopStationaryDetection() {
        stationaryTimer?.invalidate()
        stationaryTimer = nil
    }
    
    private func checkStationary() {
        guard let lastMovement = lastMovementTime else { return }
        let stationaryMinutes = Date().timeIntervalSince(lastMovement) / 60
        
        if stationaryMinutes >= AppConstants.autoStopStationaryMinutes {
            Task {
                try? await stopTrip()
                // TODO: Send notification that trip was auto-stopped
            }
        }
    }
    
    private func reverseGeocode(location: CLLocation, for trip: Trip, isStart: Bool) async {
        // Note: CLGeocoder.reverseGeocodeLocation is deprecated in iOS 26.0 in favor of MapKit's MKReverseGeocodingRequest.
        // We continue using CLGeocoder for iOS 17+ compatibility. This warning is informational and doesn't affect functionality.
        // TODO: Migrate to MapKit's MKReverseGeocodingRequest when dropping iOS 25 support
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                if isStart {
                    trip.startAddress = formatAddress(placemark)
                    trip.startCity = placemark.locality
                    trip.startState = placemark.administrativeArea
                    trip.startCountry = placemark.country
                } else {
                    trip.endAddress = formatAddress(placemark)
                    trip.endCity = placemark.locality
                    trip.endState = placemark.administrativeArea
                    trip.endCountry = placemark.country
                }
            }
        } catch {
            // Geocoding failed, continue without address
        }
    }
    
    private func formatAddress(_ placemark: CLPlacemark) -> String {
        [placemark.name, placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
    
    // MARK: - Public Refresh
    /// Expose a way for UI layers to resync active trip state when the app is opened via intents
    func refreshActiveTripState() {
        restoreActiveTripIfNeeded()
    }
}

