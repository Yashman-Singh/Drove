//
//  SettingsViewModel.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData
import CoreLocation

@Observable
final class SettingsViewModel {
    // MARK: - Dependencies
    let locationManager: LocationManager
    
    // MARK: - State
    var locationPermissionStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    // MARK: - Initialization
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    // MARK: - Public Methods
    
    func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Data Deletion
    
    func deleteAllTrips(context: ModelContext) throws {
        let descriptor = FetchDescriptor<Trip>()
        let trips = try context.fetch(descriptor)
        for trip in trips {
            context.delete(trip)
        }
        try context.save()
    }
    
    func deleteAllVehicles(context: ModelContext) throws {
        // First, remove vehicle references from trips
        let tripDescriptor = FetchDescriptor<Trip>()
        if let trips = try? context.fetch(tripDescriptor) {
            for trip in trips {
                trip.vehicle = nil
            }
        }
        
        // Then delete all vehicles
        let vehicleDescriptor = FetchDescriptor<Vehicle>()
        let vehicles = try context.fetch(vehicleDescriptor)
        for vehicle in vehicles {
            context.delete(vehicle)
        }
        
        // Clear default vehicle preference
        UserDefaults.standard.removeObject(forKey: AppConstants.defaultVehicleIDKey)
        
        try context.save()
    }
    
    func deleteAllData(context: ModelContext) throws {
        try deleteAllTrips(context: context)
        try deleteAllVehicles(context: context)
    }
    
    var locationPermissionDescription: String {
        switch locationPermissionStatus {
        case .notDetermined:
            return "Not determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedWhenInUse:
            return "When in use"
        case .authorizedAlways:
            return "Always"
        @unknown default:
            return "Unknown"
        }
    }
    
    var needsLocationPermission: Bool {
        locationPermissionStatus == .denied || 
        locationPermissionStatus == .restricted ||
        locationPermissionStatus == .notDetermined
    }
    
    var needsPermissionUpgrade: Bool {
        locationPermissionStatus == .authorizedWhenInUse
    }
}
