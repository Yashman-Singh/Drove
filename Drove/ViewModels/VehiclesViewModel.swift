//
//  VehiclesViewModel.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

@Observable
final class VehiclesViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    
    // MARK: - State
    private var defaultVehicleIDString: String {
        get {
            UserDefaults.standard.string(forKey: AppConstants.defaultVehicleIDKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: AppConstants.defaultVehicleIDKey)
        }
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    func fetchVehicles() -> [Vehicle] {
        let descriptor = FetchDescriptor<Vehicle>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchDefaultVehicle() -> Vehicle? {
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
    
    func setDefaultVehicle(_ vehicle: Vehicle?) {
        defaultVehicleIDString = vehicle?.id.uuidString ?? ""
    }
    
    func createVehicle(name: String, make: String?, model: String?, year: Int?) {
        let vehicle = Vehicle(name: name)
        vehicle.make = make
        vehicle.model = model
        vehicle.year = year
        modelContext.insert(vehicle)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save vehicle: \(error)")
        }
    }
    
    func updateVehicle(_ vehicle: Vehicle, name: String, make: String?, model: String?, year: Int?) {
        vehicle.name = name
        vehicle.make = make
        vehicle.model = model
        vehicle.year = year
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update vehicle: \(error)")
        }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        // If this is the default vehicle, clear the default
        if defaultVehicleIDString == vehicle.id.uuidString {
            defaultVehicleIDString = ""
        }
        
        // Set all trips with this vehicle to nil
        // Note: SwiftData predicates don't support deep relationship comparisons,
        // so we fetch all trips and filter in code
        let descriptor = FetchDescriptor<Trip>()
        
        if let trips = try? modelContext.fetch(descriptor) {
            for trip in trips {
                if trip.vehicle?.id == vehicle.id {
                    trip.vehicle = nil
                }
            }
        }
        
        modelContext.delete(vehicle)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete vehicle: \(error)")
        }
    }
    
    func isDefaultVehicle(_ vehicle: Vehicle) -> Bool {
        defaultVehicleIDString == vehicle.id.uuidString
    }
}
