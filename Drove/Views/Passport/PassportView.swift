//
//  PassportView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct PassportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.selectedTab) private var selectedTab
    @Environment(\.shouldStartTrip) private var shouldStartTrip
    @State private var viewModel: PassportViewModel?
    @State private var selectedYearOption: YearOption = .allTime
    
    @Query(filter: #Predicate<Trip> { !$0.isHidden }) private var allTrips: [Trip]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if allTrips.isEmpty {
                    // Empty State
                    EmptyStateView(
                        icon: "book.closed.fill",
                        title: "Your passport awaits",
                        description: "Record trips to see your lifetime driving statistics",
                        actionTitle: "Start Trip",
                        action: {
                            // Switch to Home tab and trigger trip start
                            selectedTab.wrappedValue = 0
                            shouldStartTrip.wrappedValue = true
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if let viewModel = viewModel {
                    VStack(spacing: AppConstants.standardPadding) {
                        // Header
                        headerSection
                            .padding(.horizontal, AppConstants.standardPadding)
                            .padding(.top, AppConstants.standardPadding)
                        
                        // Year Picker
                        if !viewModel.availableYears.isEmpty {
                            yearPickerSection(viewModel: viewModel)
                                .padding(.horizontal, AppConstants.standardPadding)
                        }
                        
                        // Primary Stats Grid
                        StatsGridView(viewModel: viewModel)
                        
                        // States Visited
                        StatesMapView(viewModel: viewModel)
                            .padding(.horizontal, AppConstants.standardPadding)
                        
                        // Milestones
                        MilestoneCard(viewModel: viewModel)
                            .padding(.horizontal, AppConstants.standardPadding)
                        
                        // Vehicle Stats
                        VehicleStatsSection(viewModel: viewModel)
                            .padding(.horizontal, AppConstants.standardPadding)
                        
                        // Innovative Stats
                        InnovativeStatsSection(viewModel: viewModel)
                        
                        // Bottom padding
                        Spacer()
                            .frame(height: AppConstants.standardPadding)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("")
            .onAppear {
                if viewModel == nil {
                    viewModel = PassportViewModel(modelContext: modelContext)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Driving Passport")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Lifetime driving statistics")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func yearPickerSection(viewModel: PassportViewModel) -> some View {
        Picker("Year", selection: $selectedYearOption) {
            ForEach(viewModel.yearOptions) { option in
                Text(option.displayName)
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedYearOption) { oldValue, newValue in
            switch newValue {
            case .allTime:
                viewModel.selectedYear = nil
            case .year(let year):
                viewModel.selectedYear = year
            }
        }
        .onAppear {
            // Sync initial state
            if let year = viewModel.selectedYear {
                selectedYearOption = .year(year)
            } else {
                selectedYearOption = .allTime
            }
        }
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    
    return PassportView()
        .modelContainer(container)
}
