//
//  StopTripIntent.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import AppIntents
import SwiftData

struct StopTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Driving Trip"
    static var description: IntentDescription = "Stops the current driving trip"
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let container = ModelContainerProvider.shared
        let context = container.mainContext
        
        let locationManager = LocationManager()
        let tripManager = TripManager(locationManager: locationManager, modelContext: context)
        
        do {
            try await tripManager.stopTrip()
        } catch let error as TripError {
            // If there's no active trip, treat this as a no-op instead of an error.
            // This makes the Siri experience idempotent: saying "stop trip" is safe
            // even if nothing is currently recording.
            if case .noTripInProgress = error {
                return .result()
            }
            throw error
        }
        
        return .result()
    }
}
