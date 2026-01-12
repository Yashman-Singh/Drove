//
//  LocationManager.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject {
    // MARK: - Published State
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var isTracking: Bool = false
    var lastError: Error?
    
    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var onLocationUpdate: ((CLLocation) -> Void)?
    private var currentLocationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // MARK: - Configuration Constants
    private enum Config {
        static let trackingAccuracy = kCLLocationAccuracyBestForNavigation
        static let idleAccuracy = kCLLocationAccuracyThreeKilometers
        static let distanceFilter: CLLocationDistance = 10 // meters
        static let locationRequestTimeout: TimeInterval = 10 // seconds
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            // User previously granted "When In Use" - request upgrade to "Always"
            // iOS will show a prompt explaining the difference
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            // Can't request - must direct user to Settings
            break
        case .authorizedAlways:
            // Already have full access
            break
        @unknown default:
            break
        }
    }
    
    var canTrackInBackground: Bool {
        authorizationStatus == .authorizedAlways
    }
    
    var needsPermissionUpgrade: Bool {
        authorizationStatus == .authorizedWhenInUse
    }
    
    func startTracking(onUpdate: @escaping (CLLocation) -> Void) {
        onLocationUpdate = onUpdate
        locationManager.desiredAccuracy = Config.trackingAccuracy
        locationManager.distanceFilter = Config.distanceFilter
        locationManager.startUpdatingLocation()
        isTracking = true
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        onLocationUpdate = nil
        isTracking = false
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        // Check if we already have a recent location (within 10 seconds)
        if let location = currentLocation,
           abs(location.timestamp.timeIntervalSinceNow) < 10 {
            return location
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Store continuation for delegate callback
            currentLocationContinuation = continuation
            
            // Request one-time location update
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()
        }
    }
    
    /// Requests location permission and waits briefly for an initial location fix
    func requestInitialLocation() async {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        // Wait up to 3 seconds for a location
        for _ in 0..<30 {
            if currentLocation != nil {
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        onLocationUpdate?(location)
        
        // Handle one-shot location request
        if let continuation = currentLocationContinuation {
            currentLocationContinuation = nil
            continuation.resume(returning: location)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error
        
        // Handle one-shot location request failure
        if let continuation = currentLocationContinuation {
            currentLocationContinuation = nil
            continuation.resume(throwing: error)
        }
    }
}

