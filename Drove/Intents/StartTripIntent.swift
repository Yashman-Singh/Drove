//
//  StartTripIntent.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import AppIntents
import Foundation
import SwiftData
import CoreLocation

struct StartTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Driving Trip"
    static var description: IntentDescription = "Starts recording a new driving trip"
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let container = ModelContainerProvider.shared
        let context = container.mainContext
        
        let locationManager = LocationManager()
        let tripManager = TripManager(locationManager: locationManager, modelContext: context)
        
        // Get default vehicle if one is set
        let defaultVehicle = fetchDefaultVehicle(context: context)
        
        do {
            try await tripManager.startTrip(vehicle: defaultVehicle)
        } catch let error as TripError {
            // If a trip is already in progress, treat this as success.
            // This makes \"Start Trip\" idempotent for Siri.
            if case .tripAlreadyInProgress = error {
                return .result()
            }
            throw error
        }
        
        return .result()
    }
    
    @MainActor
    private func fetchDefaultVehicle(context: ModelContext) -> Vehicle? {
        let defaultVehicleIDString = UserDefaults.standard.string(forKey: AppConstants.defaultVehicleIDKey) ?? ""
        guard let vehicleID = UUID(uuidString: defaultVehicleIDString) else {
            return nil
        }
        
        // SwiftData predicates can't compare UUIDs directly, so fetch all and filter
        let descriptor = FetchDescriptor<Vehicle>()
        if let vehicles = try? context.fetch(descriptor) {
            return vehicles.first(where: { $0.id == vehicleID })
        }
        return nil
    }
}
