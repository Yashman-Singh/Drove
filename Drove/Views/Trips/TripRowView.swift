//
//  TripRowView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct TripRowView: View {
    let trip: Trip
    
    var body: some View {
        NavigationLink {
            TripDetailView(trip: trip)
        } label: {
            HStack(spacing: AppConstants.standardPadding) {
                // Category Icon
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)
                
                // Trip Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tripDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Text(trip.startTime.shortDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let vehicle = trip.vehicle {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(vehicle.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trip.distanceMiles.formattedMiles)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(trip.durationSeconds.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, AppConstants.standardPadding)
        }
    }
    
    private var categoryIcon: String {
        TripCategory(rawValue: trip.category)?.iconName ?? TripCategory.other.iconName
    }
    
    private var tripDescription: String {
        if let startCity = trip.startCity, let endCity = trip.endCity {
            return "\(startCity) → \(endCity)"
        } else if let startCity = trip.startCity {
            return "\(startCity) → ..."
        } else if let endCity = trip.endCity {
            return "... → \(endCity)"
        } else if let startState = trip.startState, let endState = trip.endState {
            return "\(startState) → \(endState)"
        } else {
            return "Trip"
        }
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    
    let trip = Trip(startLatitude: 37.7749, startLongitude: -122.4194)
    trip.startCity = "San Francisco"
    trip.endCity = "Los Angeles"
    trip.distanceMeters = 560000
    trip.endTime = Date().addingTimeInterval(-3600)
    trip.category = TripCategory.roadTrip.rawValue
    
    return NavigationStack {
        List {
            TripRowView(trip: trip)
        }
        .modelContainer(container)
    }
}
