//
//  PassportViewModel.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData
import Observation

@Observable
final class PassportViewModel {
    // MARK: - Dependencies
    let statsManager: StatsManager
    
    // MARK: - State
    var isLoading: Bool = false
    var errorMessage: String?
    var selectedYear: Int? = nil {
        didSet {
            statsManager.selectedYear = selectedYear
        }
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.statsManager = StatsManager(modelContext: modelContext)
    }
    
    // MARK: - Year Filtering
    
    var availableYears: [Int] {
        statsManager.availableYears()
    }
    
    var yearOptions: [YearOption] {
        var options: [YearOption] = [.allTime]
        options.append(contentsOf: availableYears.map { .year($0) })
        return options
    }
    
    // MARK: - Formatted Stats (Required)
    
    var totalMilesFormatted: String {
        statsManager.totalMiles().formattedLargeNumber + " mi"
    }
    
    var totalTimeFormatted: String {
        statsManager.totalDrivingTime().formattedAsDays
    }
    
    var totalTripsFormatted: String {
        "\(statsManager.totalTrips())"
    }
    
    var statesVisitedCount: Int {
        statsManager.statesVisited().count
    }
    
    var statesVisitedFormatted: String {
        "\(statesVisitedCount) / 50"
    }
    
    var earthCircumnavigationsFormatted: String {
        String(format: "%.2fx", statsManager.earthCircumnavigations())
    }
    
    var milesThisYearFormatted: String {
        statsManager.milesThisYear().formattedLargeNumber + " mi"
    }
    
    var milesThisMonthFormatted: String {
        statsManager.milesThisMonth().formattedLargeNumber + " mi"
    }
    
    // MARK: - Formatted Stats (Innovative)
    
    var averageTripDistanceFormatted: String {
        statsManager.averageTripDistance().formattedMiles
    }
    
    var averageSpeedFormatted: String {
        String(format: "%.1f mph", statsManager.averageSpeed())
    }
    
    var uniqueCitiesFormatted: String {
        "\(statsManager.uniqueCitiesVisited())"
    }
    
    var averageTripsPerWeekFormatted: String {
        String(format: "%.1f", statsManager.averageTripsPerWeek())
    }
    
    var uniqueRoutesFormatted: String {
        "\(statsManager.uniqueRoutes())"
    }
    
    var distanceToMoonFormatted: String {
        String(format: "%.3fx", statsManager.distanceToMoon())
    }
    
    var distanceToMarsFormatted: String {
        String(format: "%.5fx", statsManager.distanceToMars())
    }
    
    // MARK: - Records
    
    var longestTrip: Trip? {
        statsManager.longestTrip()
    }
    
    var fastestTrip: Trip? {
        statsManager.fastestTrip()
    }
    
    var longestDay: (date: Date, miles: Double)? {
        statsManager.longestDay()
    }
    
    var mostActiveMonth: (month: Int, year: Int, miles: Double)? {
        statsManager.mostActiveMonth()
    }
    
    var mostVisitedCity: String? {
        statsManager.mostVisitedCity()
    }
    
    // MARK: - Patterns
    
    var categoryBreakdown: [TripCategory: Int] {
        statsManager.categoryBreakdown()
    }
    
    var timeOfDayPattern: (morning: Int, afternoon: Int, evening: Int, night: Int) {
        statsManager.timeOfDayPattern()
    }
    
    var consecutiveDaysStreak: Int {
        statsManager.consecutiveDaysWithTrips()
    }
    
    // MARK: - States
    
    var statesVisited: Set<String> {
        statsManager.statesVisited()
    }
    
    // MARK: - Vehicle Stats
    
    var mostUsedVehicle: Vehicle? {
        statsManager.mostUsedVehicle()
    }
    
    var vehicleBreakdown: [(vehicle: Vehicle, miles: Double, trips: Int)] {
        statsManager.vehicleBreakdown()
    }
    
    var averageDistancePerVehicle: Double {
        statsManager.averageDistancePerVehicle()
    }
    
    var tripsWithoutVehicle: Int {
        statsManager.tripsWithoutVehicle()
    }
    
    func totalMilesForVehicle(_ vehicle: Vehicle) -> Double {
        statsManager.totalMilesForVehicle(vehicle)
    }
    
    func tripsForVehicle(_ vehicle: Vehicle) -> Int {
        statsManager.tripsForVehicle(vehicle)
    }
    
    // MARK: - Milestones
    
    func nextDistanceMilestone() -> (current: Double, target: Double, progress: Double)? {
        let total = statsManager.totalMiles()
        let milestones = Milestones.distanceMilestones
        
        for milestone in milestones {
            if total < milestone {
                return (current: total, target: milestone, progress: total / milestone)
            }
        }
        
        return nil
    }
    
    func nextStateMilestone() -> (current: Int, target: Int, progress: Double)? {
        let current = statesVisitedCount
        let milestones = Milestones.stateMilestones
        
        for milestone in milestones {
            if current < milestone {
                return (current: current, target: milestone, progress: Double(current) / Double(milestone))
            }
        }
        
        return nil
    }
    
    func nextTripMilestone() -> (current: Int, target: Int, progress: Double)? {
        let current = statsManager.totalTrips()
        let milestones = Milestones.tripMilestones
        
        for milestone in milestones {
            if current < milestone {
                return (current: current, target: milestone, progress: Double(current) / Double(milestone))
            }
        }
        
        return nil
    }
    
    func nextMilestone() -> (type: String, current: String, target: String, progress: Double)? {
        let distance = nextDistanceMilestone()
        let states = nextStateMilestone()
        let trips = nextTripMilestone()
        
        var candidates: [(type: String, current: String, target: String, progress: Double)] = []
        
        if let d = distance {
            candidates.append(("Distance", d.current.formattedLargeNumber + " mi", d.target.formattedLargeNumber + " mi", d.progress))
        }
        
        if let s = states {
            candidates.append(("States", "\(s.current)", "\(s.target)", s.progress))
        }
        
        if let t = trips {
            candidates.append(("Trips", "\(t.current)", "\(t.target)", t.progress))
        }
        
        return candidates.max(by: { $0.progress < $1.progress })
    }
}

enum YearOption: Identifiable, Hashable {
    case allTime
    case year(Int)
    
    var id: String {
        switch self {
        case .allTime:
            return "all-time"
        case .year(let year):
            return "\(year)"
        }
    }
    
    var displayName: String {
        switch self {
        case .allTime:
            return "All-time"
        case .year(let year):
            return "\(year)"
        }
    }
}
