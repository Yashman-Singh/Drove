//
//  InnovativeStatsSection.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct InnovativeStatsSection: View {
    let viewModel: PassportViewModel
    @State private var isRecordsExpanded = true
    @State private var isPatternsExpanded = false
    @State private var isComparisonsExpanded = false
    
    var body: some View {
        VStack(spacing: AppConstants.standardPadding) {
            // Records Section
            recordsSection
            
            // Patterns Section
            patternsSection
            
            // Fun Comparisons Section
            comparisonsSection
        }
        .padding(.horizontal, AppConstants.standardPadding)
    }
    
    // MARK: - Records Section
    
    private var recordsSection: some View {
        DisclosureGroup(isExpanded: $isRecordsExpanded) {
            VStack(spacing: 12) {
                if let longestTrip = viewModel.longestTrip {
                    RecordRow(
                        icon: "arrow.right.circle.fill",
                        title: "Longest Trip",
                        value: longestTrip.distanceMiles.formattedMiles,
                        subtitle: longestTripDescription(longestTrip)
                    )
                }
                
                if let fastestTrip = viewModel.fastestTrip,
                   let speed = calculateAverageSpeed(trip: fastestTrip) {
                    RecordRow(
                        icon: "speedometer",
                        title: "Fastest Trip",
                        value: String(format: "%.1f mph", speed),
                        subtitle: fastestTripDescription(fastestTrip)
                    )
                }
                
                if let longestDay = viewModel.longestDay {
                    RecordRow(
                        icon: "calendar.badge.clock",
                        title: "Longest Day",
                        value: longestDay.miles.formattedMiles,
                        subtitle: longestDay.date.shortDate
                    )
                }
                
                if let mostVisitedCity = viewModel.mostVisitedCity {
                    RecordRow(
                        icon: "building.2.fill",
                        title: "Most Visited City",
                        value: mostVisitedCity,
                        subtitle: "Favorite destination"
                    )
                }
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.accentColor)
                Text("Records")
                    .font(.headline)
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
    
    // MARK: - Patterns Section
    
    private var patternsSection: some View {
        DisclosureGroup(isExpanded: $isPatternsExpanded) {
            VStack(spacing: 12) {
                if let mostActiveMonth = viewModel.mostActiveMonth {
                    RecordRow(
                        icon: "calendar",
                        title: "Most Active Month",
                        value: monthName(mostActiveMonth.month) + " \(mostActiveMonth.year)",
                        subtitle: mostActiveMonth.miles.formattedMiles
                    )
                }
                
                RecordRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Avg Trips Per Week",
                    value: viewModel.averageTripsPerWeekFormatted,
                    subtitle: "Consistent driving"
                )
                
                RecordRow(
                    icon: "clock.fill",
                    title: "Consecutive Days",
                    value: "\(viewModel.consecutiveDaysStreak)",
                    subtitle: "Longest streak"
                )
                
                // Category Breakdown
                if !viewModel.categoryBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Breakdown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(Array(viewModel.categoryBreakdown.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                                Text(category.displayName)
                                    .font(.caption)
                                Spacer()
                                Text("\(viewModel.categoryBreakdown[category] ?? 0)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Time of Day Pattern
                let timePattern = viewModel.timeOfDayPattern
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time of Day Pattern")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 16) {
                        TimePatternItem(icon: "sunrise.fill", label: "Morning", count: timePattern.morning)
                        TimePatternItem(icon: "sun.max.fill", label: "Afternoon", count: timePattern.afternoon)
                        TimePatternItem(icon: "sunset.fill", label: "Evening", count: timePattern.evening)
                        TimePatternItem(icon: "moon.fill", label: "Night", count: timePattern.night)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)
                Text("Patterns")
                    .font(.headline)
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
    
    // MARK: - Comparisons Section
    
    private var comparisonsSection: some View {
        DisclosureGroup(isExpanded: $isComparisonsExpanded) {
            VStack(spacing: 12) {
                ComparisonRow(
                    icon: "globe.americas.fill",
                    title: "Around Earth",
                    value: viewModel.earthCircumnavigationsFormatted
                )
                
                ComparisonRow(
                    icon: "moon.fill",
                    title: "To the Moon",
                    value: viewModel.distanceToMoonFormatted
                )
                
                ComparisonRow(
                    icon: "sparkles",
                    title: "To Mars",
                    value: viewModel.distanceToMarsFormatted
                )
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                Text("Fun Comparisons")
                    .font(.headline)
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
    
    // MARK: - Helper Methods
    
    private func longestTripDescription(_ trip: Trip) -> String {
        if let startCity = trip.startCity, let endCity = trip.endCity {
            return "\(startCity) → \(endCity)"
        }
        return trip.startTime.shortDate
    }
    
    private func fastestTripDescription(_ trip: Trip) -> String {
        if let startCity = trip.startCity, let endCity = trip.endCity {
            return "\(startCity) → \(endCity)"
        }
        return trip.startTime.shortDate
    }
    
    private func calculateAverageSpeed(trip: Trip) -> Double? {
        guard trip.durationSeconds > 0 else { return nil }
        let hours = trip.durationSeconds / 3600
        guard hours > 0 else { return nil }
        return trip.distanceMiles / hours
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(month: month))!
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct RecordRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ComparisonRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct TimePatternItem: View {
    let icon: String
    let label: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext
    
    let viewModel = PassportViewModel(modelContext: context)
    
    return ScrollView {
        InnovativeStatsSection(viewModel: viewModel)
    }
    .modelContainer(container)
}
