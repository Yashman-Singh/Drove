//
//  HomeViewModel.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData
import CoreLocation

@Observable
final class HomeViewModel {
    // MARK: - Dependencies
    let tripManager: TripManager
    let locationManager: LocationManager
    private let modelContext: ModelContext
    
    // MARK: - State
    var errorMessage: String?
    var showPermissionAlert: Bool = false
    var isStartingTrip: Bool = false
    var isStoppingTrip: Bool = false
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        let locationManager = LocationManager()
        self.locationManager = locationManager
        self.modelContext = modelContext
        self.tripManager = TripManager(locationManager: locationManager, modelContext: modelContext)
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        locationManager.requestAuthorization()
    }
    
    func startTrip() async {
        guard !isStartingTrip else { return }
        
        // Check authorization status
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            errorMessage = "Location permission is required to track trips. Please enable it in Settings."
            showPermissionAlert = true
            return
        case .notDetermined, .authorizedWhenInUse:
            // Request permission first
            locationManager.requestAuthorization()
            // Wait a moment for the system prompt, then check again
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if locationManager.authorizationStatus != .authorizedAlways {
                errorMessage = "Background location permission is required for trip tracking."
                showPermissionAlert = true
                return
            }
        case .authorizedAlways:
            break
        @unknown default:
            break
        }
        
        isStartingTrip = true
        errorMessage = nil
        
        // Get default vehicle if one is set
        let defaultVehicle = fetchDefaultVehicle()
        
        do {
            try await tripManager.startTrip(vehicle: defaultVehicle)
        } catch {
            handleError(error)
        }
        
        isStartingTrip = false
    }
    
    func stopTrip() async {
        guard !isStoppingTrip else { return }
        
        isStoppingTrip = true
        errorMessage = nil
        
        do {
            try await tripManager.stopTrip()
        } catch {
            handleError(error)
        }
        
        isStoppingTrip = false
    }
    
    func handleError(_ error: Error) {
        if let tripError = error as? TripError {
            errorMessage = tripError.localizedDescription
        } else if let clError = error as? CLError {
            // Provide user-friendly messages for CoreLocation errors
            switch clError.code {
            case .locationUnknown:
                #if targetEnvironment(simulator)
                errorMessage = "Unable to get location. In the Simulator, go to Features → Location and select a location or use 'City Run' to simulate movement."
                #else
                errorMessage = "Unable to determine your location. Please ensure you're in an area with GPS signal."
                #endif
            case .denied:
                errorMessage = "Location access was denied. Please enable it in Settings."
            case .network:
                errorMessage = "Network error while getting location. Please check your connection."
            default:
                errorMessage = "Location error: \(clError.localizedDescription)"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Computed Properties
    
    var canStartTrip: Bool {
        !isStartingTrip && !tripManager.isRecording && locationManager.authorizationStatus != .denied
    }
    
    var needsPermission: Bool {
        locationManager.authorizationStatus == .notDetermined || 
        locationManager.authorizationStatus == .denied ||
        locationManager.authorizationStatus == .restricted
    }
    
    // MARK: - Sync
    func refreshActiveTripState() {
        tripManager.refreshActiveTripState()
    }
    
    // MARK: - Private Methods
    
    private func fetchDefaultVehicle() -> Vehicle? {
        let defaultVehicleIDString = UserDefaults.standard.string(forKey: AppConstants.defaultVehicleIDKey) ?? ""
        guard let vehicleID = UUID(uuidString: defaultVehicleIDString) else {
            return nil
        }
        
        // SwiftData predicates can't compare UUIDs directly, so fetch all and filter
        let descriptor = FetchDescriptor<Vehicle>()
        if let vehicles = try? modelContext.fetch(descriptor) {
            return vehicles.first(where: { $0.id == vehicleID })
        }
        return nil
    }
}

