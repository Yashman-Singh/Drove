//
//  StatsManager.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftData
import Observation
import Foundation

@Observable
final class StatsManager {
    private let modelContext: ModelContext
    var selectedYear: Int? = nil // nil means all-time
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Year Filtering
    
    func availableYears() -> [Int] {
        let trips = fetchAllTrips(includeHidden: false)
        let calendar = Calendar.current
        let years = Set(trips.map { calendar.component(.year, from: $0.startTime) })
        return Array(years).sorted(by: >) // Most recent first
    }
    
    // MARK: - Required Stats
    
    func totalMiles() -> Double {
        let trips = getFilteredTrips()
        return trips.reduce(0) { $0 + $1.distanceMiles }
    }
    
    func totalTrips() -> Int {
        getFilteredTrips().count
    }
    
    func totalDrivingTime() -> TimeInterval {
        let trips = getFilteredTrips()
        return trips.reduce(0) { $0 + $1.durationSeconds }
    }
    
    func statesVisited() -> Set<String> {
        let trips = getFilteredTrips()
        var states = Set<String>()
        for trip in trips {
            if let state = trip.startState { states.insert(state) }
            if let state = trip.endState { states.insert(state) }
        }
        return states
    }
    
    func earthCircumnavigations() -> Double {
        totalMiles() / AppConstants.earthCircumferenceMiles
    }
    
    func milesThisYear() -> Double {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date())) else {
            return 0
        }
        let trips = fetchTrips(from: startOfYear)
        return trips.reduce(0) { $0 + $1.distanceMiles }
    }
    
    func milesThisMonth() -> Double {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return 0
        }
        let trips = fetchTrips(from: startOfMonth)
        return trips.reduce(0) { $0 + $1.distanceMiles }
    }
    
    func longestTrip() -> Trip? {
        getFilteredTrips()
            .max(by: { $0.distanceMeters < $1.distanceMeters })
    }
    
    func mostVisitedCity() -> String? {
        let trips = getFilteredTrips()
        var cityCount: [String: Int] = [:]
        for trip in trips {
            if let city = trip.endCity {
                cityCount[city, default: 0] += 1
            }
        }
        return cityCount.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Innovative Stats
    
    func averageTripDistance() -> Double {
        let trips = totalTrips()
        guard trips > 0 else { return 0 }
        return totalMiles() / Double(trips)
    }
    
    func averageSpeed() -> Double {
        let totalHours = totalDrivingTime() / 3600
        guard totalHours > 0 else { return 0 }
        return totalMiles() / totalHours
    }
    
    func longestDay() -> (date: Date, miles: Double)? {
        let trips = getFilteredTrips()
        guard !trips.isEmpty else { return nil }
        
        var dayMiles: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for trip in trips {
            let day = calendar.startOfDay(for: trip.startTime)
            dayMiles[day, default: 0] += trip.distanceMiles
        }
        
        guard let maxDay = dayMiles.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        return (date: maxDay.key, miles: maxDay.value)
    }
    
    func mostActiveMonth() -> (month: Int, year: Int, miles: Double)? {
        let trips = getFilteredTrips()
        guard !trips.isEmpty else { return nil }
        
        var monthMiles: [String: Double] = [:]
        let calendar = Calendar.current
        
        for trip in trips {
            let components = calendar.dateComponents([.year, .month], from: trip.startTime)
            if let year = components.year, let month = components.month {
                let key = "\(year)-\(month)"
                monthMiles[key, default: 0] += trip.distanceMiles
            }
        }
        
        guard let maxMonth = monthMiles.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        let parts = maxMonth.key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else {
            return nil
        }
        
        return (month: month, year: year, miles: maxMonth.value)
    }
    
    func uniqueCitiesVisited() -> Int {
        let trips = getFilteredTrips()
        var cities = Set<String>()
        for trip in trips {
            if let city = trip.startCity { cities.insert(city) }
            if let city = trip.endCity { cities.insert(city) }
        }
        return cities.count
    }
    
    func averageTripsPerWeek() -> Double {
        let trips = getFilteredTrips()
        guard !trips.isEmpty else { return 0 }
        
        let sortedTrips = trips.sorted { $0.startTime < $1.startTime }
        guard let firstTrip = sortedTrips.first else { return 0 }
        
        let daysSinceFirst = Date().timeIntervalSince(firstTrip.startTime) / 86400
        guard daysSinceFirst > 0 else { return 0 }
        
        let weeks = daysSinceFirst / 7
        return Double(trips.count) / weeks
    }
    
    func fastestTrip() -> Trip? {
        let trips = getFilteredTrips()
        guard !trips.isEmpty else { return nil }
        
        var fastestTrip: Trip?
        var fastestSpeed: Double = 0
        
        for trip in trips {
            guard let speed = calculateAverageSpeed(trip: trip), speed > 0 else { continue }
            if speed > fastestSpeed {
                fastestSpeed = speed
                fastestTrip = trip
            }
        }
        
        return fastestTrip
    }
    
    func uniqueRoutes() -> Int {
        let trips = getFilteredTrips()
        var routes = Set<String>()
        
        for trip in trips {
            let start = trip.startCity ?? trip.startState ?? "Unknown"
            let end = trip.endCity ?? trip.endState ?? "Unknown"
            let route = "\(start) → \(end)"
            routes.insert(route)
        }
        
        return routes.count
    }
    
    func categoryBreakdown() -> [TripCategory: Int] {
        let trips = getFilteredTrips()
        var breakdown: [TripCategory: Int] = [:]
        
        for trip in trips {
            if let category = TripCategory(rawValue: trip.category) {
                breakdown[category, default: 0] += 1
            }
        }
        
        return breakdown
    }
    
    func timeOfDayPattern() -> (morning: Int, afternoon: Int, evening: Int, night: Int) {
        let trips = getFilteredTrips()
        var morning = 0
        var afternoon = 0
        var evening = 0
        var night = 0
        
        let calendar = Calendar.current
        
        for trip in trips {
            let hour = calendar.component(.hour, from: trip.startTime)
            
            switch hour {
            case 5..<12:
                morning += 1
            case 12..<17:
                afternoon += 1
            case 17..<21:
                evening += 1
            default:
                night += 1
            }
        }
        
        return (morning: morning, afternoon: afternoon, evening: evening, night: night)
    }
    
    func consecutiveDaysWithTrips() -> Int {
        let trips = getFilteredTrips()
        guard !trips.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let daysWithTrips = Set(trips.map { calendar.startOfDay(for: $0.startTime) })
        let sortedDays = daysWithTrips.sorted()
        
        guard !sortedDays.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDays.count {
            if let daysBetween = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day,
               daysBetween == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
    
    func distanceToMoon() -> Double {
        totalMiles() / Milestones.moonDistanceMiles
    }
    
    func distanceToMars() -> Double {
        totalMiles() / Milestones.marsDistanceMiles
    }
    
    // MARK: - Vehicle Stats
    
    func totalMilesForVehicle(_ vehicle: Vehicle) -> Double {
        let trips = getFilteredTrips().filter { $0.vehicle?.id == vehicle.id }
        return trips.reduce(0) { $0 + $1.distanceMiles }
    }
    
    func tripsForVehicle(_ vehicle: Vehicle) -> Int {
        getFilteredTrips().filter { $0.vehicle?.id == vehicle.id }.count
    }
    
    func mostUsedVehicle() -> Vehicle? {
        let trips = getFilteredTrips()
        var vehicleMiles: [UUID: Double] = [:]
        
        for trip in trips {
            if let vehicle = trip.vehicle {
                vehicleMiles[vehicle.id, default: 0] += trip.distanceMiles
            }
        }
        
        guard let maxVehicleID = vehicleMiles.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        // Fetch the vehicle from context
        // SwiftData predicates can't compare UUIDs directly, so fetch all and filter
        let descriptor = FetchDescriptor<Vehicle>()
        if let vehicles = try? modelContext.fetch(descriptor) {
            return vehicles.first(where: { $0.id == maxVehicleID })
        }
        return nil
    }
    
    func vehicleBreakdown() -> [(vehicle: Vehicle, miles: Double, trips: Int)] {
        let trips = getFilteredTrips()
        var vehicleData: [UUID: (miles: Double, trips: Int)] = [:]
        
        for trip in trips {
            if let vehicle = trip.vehicle {
                let existing = vehicleData[vehicle.id] ?? (miles: 0, trips: 0)
                vehicleData[vehicle.id] = (
                    miles: existing.miles + trip.distanceMiles,
                    trips: existing.trips + 1
                )
            }
        }
        
        // Fetch all vehicles and create breakdown
        let descriptor = FetchDescriptor<Vehicle>()
        guard let allVehicles = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        return allVehicles.compactMap { vehicle in
            guard let data = vehicleData[vehicle.id] else { return nil }
            return (vehicle: vehicle, miles: data.miles, trips: data.trips)
        }.sorted { $0.miles > $1.miles }
    }
    
    func averageDistancePerVehicle() -> Double {
        let breakdown = vehicleBreakdown()
        guard !breakdown.isEmpty else { return 0 }
        let totalMiles = breakdown.reduce(0) { $0 + $1.miles }
        return totalMiles / Double(breakdown.count)
    }
    
    func tripsWithoutVehicle() -> Int {
        getFilteredTrips().filter { $0.vehicle == nil }.count
    }
    
    // MARK: - Private Helpers
    
    private func getFilteredTrips() -> [Trip] {
        let trips = fetchAllTrips(includeHidden: false)
        
        guard let selectedYear = selectedYear else {
            return trips
        }
        
        let calendar = Calendar.current
        return trips.filter { calendar.component(.year, from: $0.startTime) == selectedYear }
    }
    
    private func fetchAllTrips(includeHidden: Bool) -> [Trip] {
        var descriptor = FetchDescriptor<Trip>()
        if !includeHidden {
            descriptor.predicate = #Predicate { !$0.isHidden }
        }
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func fetchTrips(from startDate: Date, to endDate: Date = Date()) -> [Trip] {
        let descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate {
                $0.startTime >= startDate &&
                $0.startTime <= endDate &&
                !$0.isHidden
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func calculateAverageSpeed(trip: Trip) -> Double? {
        guard trip.durationSeconds > 0 else { return nil }
        let hours = trip.durationSeconds / 3600
        guard hours > 0 else { return nil }
        return trip.distanceMiles / hours
    }
}
