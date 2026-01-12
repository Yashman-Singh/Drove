//
//  TripsListView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

enum TripSortOption: String, CaseIterable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case distance = "Distance"
    case duration = "Duration"
}

struct TripsListView: View {
    @Query(sort: \Trip.startTime, order: .reverse) private var allTripsQuery: [Trip]
    @Environment(\.selectedTab) private var selectedTab
    @Environment(\.shouldStartTrip) private var shouldStartTrip
    
    @State private var searchText = ""
    @State private var selectedCategory: TripCategory?
    @State private var sortOption: TripSortOption = .dateNewest
    @State private var includeHiddenTrips: Bool = true
    
    // Filter trips based on includeHiddenTrips setting
    private var allTrips: [Trip] {
        if includeHiddenTrips {
            return allTripsQuery
        } else {
            return allTripsQuery.filter { !$0.isHidden }
        }
    }
    
    // Exclude active trip from list
    private var trips: [Trip] {
        allTrips.filter { trip in
            // Exclude active trips (those without endTime)
            trip.endTime != nil
        }
    }
    
    // Debug: Count of all trips including hidden
    private var totalTripsCount: Int {
        allTripsQuery.count
    }
    
    private var hiddenTripsCount: Int {
        allTripsQuery.filter { $0.isHidden }.count
    }
    
    private var filteredTrips: [Trip] {
        var result = trips
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            result = result.filter { $0.category == selectedCategory.rawValue }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { trip in
                trip.startCity?.lowercased().contains(searchLower) ?? false ||
                trip.endCity?.lowercased().contains(searchLower) ?? false ||
                trip.startState?.lowercased().contains(searchLower) ?? false ||
                trip.endState?.lowercased().contains(searchLower) ?? false ||
                trip.notes?.lowercased().contains(searchLower) ?? false
            }
        }
        
        // Apply sort
        switch sortOption {
        case .dateNewest:
            result.sort { $0.startTime > $1.startTime }
        case .dateOldest:
            result.sort { $0.startTime < $1.startTime }
        case .distance:
            result.sort { $0.distanceMeters > $1.distanceMeters }
        case .duration:
            result.sort { $0.durationSeconds > $1.durationSeconds }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if trips.isEmpty {
                    // Empty state
                    EmptyStateView(
                        icon: "car.fill",
                        title: "No trips yet",
                        description: "Start your first trip to begin building your driving passport",
                        actionTitle: "Start Trip",
                        action: {
                            // Switch to Home tab and trigger trip start
                            selectedTab.wrappedValue = 0
                            shouldStartTrip.wrappedValue = true
                        }
                    )
                } else {
                    // Search and filters
                    VStack(spacing: AppConstants.standardPadding) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search trips...", text: $searchText)
                                .textFieldStyle(.plain)
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(AppConstants.standardPadding)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppConstants.cornerRadius)
                        .padding(.horizontal, AppConstants.standardPadding)
                        .padding(.top, AppConstants.standardPadding)
                        
                        // Filter chips and sort
                        VStack(spacing: 8) {
                            HStack {
                                // Category filter chips
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        FilterChip(
                                            title: "All",
                                            isSelected: selectedCategory == nil,
                                            action: {
                                                selectedCategory = nil
                                            }
                                        )
                                        
                                        ForEach(TripCategory.allCases, id: \.self) { category in
                                            FilterChip(
                                                title: category.displayName,
                                                icon: category.iconName,
                                                isSelected: selectedCategory == category,
                                                action: {
                                                    selectedCategory = selectedCategory == category ? nil : category
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, AppConstants.standardPadding)
                                }
                                
                                // Sort picker
                                Menu {
                                    ForEach(TripSortOption.allCases, id: \.self) { option in
                                        Button {
                                            sortOption = option
                                        } label: {
                                            HStack {
                                                Text(option.rawValue)
                                                if sortOption == option {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.arrow.down")
                                            .font(.caption)
                                        Text("Sort")
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Include hidden trips toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Toggle("Include short trips (< 0.5 mi)", isOn: $includeHiddenTrips)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if hiddenTripsCount > 0 {
                                        Text("\(hiddenTripsCount) hidden trip\(hiddenTripsCount == 1 ? "" : "s")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, AppConstants.standardPadding)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Trips list
                    if filteredTrips.isEmpty {
                        VStack(spacing: AppConstants.standardPadding) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No trips found")
                                .font(.headline)
                            Text("Try adjusting your search or filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List {
                            ForEach(filteredTrips) { trip in
                                TripRowView(trip: trip)
                                    .listRowInsets(EdgeInsets(
                                        top: 4,
                                        leading: AppConstants.standardPadding,
                                        bottom: 4,
                                        trailing: AppConstants.standardPadding
                                    ))
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Trips")
        }
    }
}

// MARK: - FilterChip Component

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    
    return TripsListView()
        .modelContainer(container)
}
