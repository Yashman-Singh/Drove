//
//  StatsGridView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct StatsGridView: View {
    let viewModel: PassportViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.standardPadding),
        GridItem(.flexible(), spacing: AppConstants.standardPadding)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: AppConstants.standardPadding) {
            // Total Miles
            StatCard(
                title: "Total Miles",
                value: viewModel.totalMilesFormatted,
                icon: "mappin.circle.fill"
            )
            
            // Total Time
            StatCard(
                title: "Total Time",
                value: viewModel.totalTimeFormatted,
                icon: "clock.fill"
            )
            
            // Total Trips
            StatCard(
                title: "Total Trips",
                value: viewModel.totalTripsFormatted,
                icon: "car.fill"
            )
            
            // States Visited
            StatCard(
                title: "States Visited",
                value: "",
                icon: "map.fill",
                inlineSubtitle: (main: "\(viewModel.statesVisitedCount)", secondary: " / 50")
            )
            
            // Earth Circumnavigations
            StatCard(
                title: "Around Earth",
                value: viewModel.earthCircumnavigationsFormatted,
                icon: "globe.americas.fill"
            )
            
            // This Year Miles
            StatCard(
                title: "This Year",
                value: viewModel.milesThisYearFormatted,
                icon: "calendar"
            )
            
            // Average Trip Distance
            StatCard(
                title: "Avg Trip",
                value: viewModel.averageTripDistanceFormatted,
                icon: "arrow.right.circle.fill"
            )
            
            // Average Speed
            StatCard(
                title: "Avg Speed",
                value: viewModel.averageSpeedFormatted,
                icon: "speedometer"
            )
        }
        .padding(.horizontal, AppConstants.standardPadding)
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext
    
    let viewModel = PassportViewModel(modelContext: context)
    
    return ScrollView {
        StatsGridView(viewModel: viewModel)
    }
    .modelContainer(container)
}
