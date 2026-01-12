//
//  HomeView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.shouldStartTrip) private var shouldStartTrip
    @State private var viewModel: HomeViewModel?
    @State private var showErrorAlert = false
    
    @Query(sort: \Trip.startTime, order: .reverse) private var allTripsQuery: [Trip]
    
    // Filter out hidden trips for display
    private var allTrips: [Trip] {
        allTripsQuery.filter { !$0.isHidden }
    }
    
    // Query for active trip - this will automatically update when App Intent creates a trip
    @Query(filter: #Predicate<Trip> { $0.endTime == nil }, sort: \Trip.startTime, order: .reverse) private var activeTrips: [Trip]
    
    private var activeTrip: Trip? {
        activeTrips.first
    }
    
    // Filter today's trips from all trips
    private var todaysTrips: [Trip] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return allTrips.filter { $0.startTime >= startOfToday }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.standardPadding) {
                    if let viewModel = viewModel {
                        if let activeTrip = activeTrip {
                            // Active Trip Card - use the trip from @Query which auto-updates
                            ActiveTripCard(trip: activeTrip, viewModel: viewModel)
                                .padding(.horizontal, AppConstants.standardPadding)
                        } else {
                            // Quick Start Section
                            quickStartSection(viewModel: viewModel)
                                .padding(.horizontal, AppConstants.standardPadding)
                        }
                        
                        // Trips Map (if trips exist - including hidden for debugging)
                        if !allTripsQuery.isEmpty {
                            TripsMapView()
                                .padding(.horizontal, AppConstants.standardPadding)
                        }
                        
                        // Today's Stats
                        todaysStatsSection
                            .padding(.horizontal, AppConstants.standardPadding)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.vertical, AppConstants.standardPadding)
            }
            .navigationTitle("Home")
            .onAppear {
                if viewModel == nil {
                    viewModel = HomeViewModel(modelContext: modelContext)
                }
                // Sync TripManager's activeTrip with the persisted trip
                if let activeTrip = activeTrip {
                    viewModel?.tripManager.activeTrip = activeTrip
                }
                
                // Debug: Log trip counts
                print("📊 HomeView appeared - Total trips in DB: \(allTripsQuery.count), Visible: \(allTrips.count), Hidden: \(allTripsQuery.filter { $0.isHidden }.count), Active: \(activeTrips.count)")
            }
            .onChange(of: activeTrip) { oldValue, newValue in
                // When activeTrip changes (from App Intent or manual start), sync with TripManager
                viewModel?.tripManager.activeTrip = newValue
            }
            .onChange(of: viewModel?.errorMessage) { oldValue, newValue in
                if newValue != nil {
                    showErrorAlert = true
                }
            }
            .onChange(of: scenePhase) { oldValue, newValue in
                if newValue == .active {
                    // Sync on app becoming active
                    if let activeTrip = activeTrip {
                        viewModel?.tripManager.activeTrip = activeTrip
                    }
                }
            }
            .onChange(of: shouldStartTrip.wrappedValue) { oldValue, newValue in
                if newValue {
                    // Start trip when triggered from empty state
                    Task {
                        await viewModel?.startTrip()
                        shouldStartTrip.wrappedValue = false
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    viewModel?.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel?.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func quickStartSection(viewModel: HomeViewModel) -> some View {
        VStack(spacing: AppConstants.standardPadding) {
            // Default Vehicle Display (if exists)
            if let defaultVehicle = fetchDefaultVehicle() {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Vehicle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(defaultVehicle.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Start Trip Button
            Button {
                Task {
                    await viewModel.startTrip()
                }
            } label: {
                HStack {
                    if viewModel.isStartingTrip {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("Start Trip")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppConstants.standardPadding * 1.5)
                .background(viewModel.canStartTrip ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(AppConstants.cornerRadius)
            }
            .disabled(!viewModel.canStartTrip || viewModel.isStartingTrip)
            
            // Last Trip Summary (if exists)
            if let lastTrip = allTrips.first {
                lastTripCard(trip: lastTrip)
            }
        }
    }
    
    @ViewBuilder
    private func lastTripCard(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Trip")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let startCity = trip.startCity, let endCity = trip.endCity {
                        Text("\(startCity) → \(endCity)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } else {
                        Text("Trip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text(trip.startTime.shortDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trip.distanceMiles.formattedMiles)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(trip.durationSeconds.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
    
    private var todaysStatsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.standardPadding) {
            Text("Today")
                .font(.headline)
            
            HStack(spacing: AppConstants.standardPadding) {
                // Miles Today
                StatCard(
                    title: "Miles",
                    value: todaysMiles.formattedMiles,
                    icon: "mappin.circle.fill"
                )
                
                // Trips Today
                StatCard(
                    title: "Trips",
                    value: "\(todaysTrips.count)",
                    icon: "car.fill"
                )
            }
        }
    }
    
    private var todaysMiles: Double {
        todaysTrips.reduce(0) { $0 + $1.distanceMiles }
    }
    
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


#Preview {
    HomeView()
        .modelContainer(for: Trip.self, inMemory: true)
}

