//
//  VehicleStatsSection.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct VehicleStatsSection: View {
    let viewModel: PassportViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if viewModel.vehicleBreakdown.isEmpty {
                Text("No vehicle data yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } else {
                VStack(spacing: 12) {
                    // Most Used Vehicle
                    if let mostUsed = viewModel.mostUsedVehicle {
                        RecordRow(
                            icon: "star.fill",
                            title: "Most Used Vehicle",
                            value: mostUsed.name,
                            subtitle: "\(viewModel.totalMilesForVehicle(mostUsed).formattedMiles) • \(viewModel.tripsForVehicle(mostUsed)) trips"
                        )
                    }
                    
                    // Vehicle Breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vehicle Breakdown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(viewModel.vehicleBreakdown, id: \.vehicle.id) { item in
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.vehicle.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if let make = item.vehicle.make, let model = item.vehicle.model {
                                        Text("\(make) \(model)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.miles.formattedMiles)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("\(item.trips) trips")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Summary Stats
                    if viewModel.vehicleBreakdown.count > 1 {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Average per Vehicle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(viewModel.averageDistancePerVehicle.formattedMiles)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            if viewModel.tripsWithoutVehicle > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Unassigned Trips")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(viewModel.tripsWithoutVehicle)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        } label: {
            HStack {
                Image(systemName: "car.2.fill")
                    .foregroundColor(.accentColor)
                Text("Vehicles")
                    .font(.headline)
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext
    
    let viewModel = PassportViewModel(modelContext: context)
    
    return ScrollView {
        VehicleStatsSection(viewModel: viewModel)
            .padding()
    }
    .modelContainer(container)
}
