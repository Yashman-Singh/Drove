//
//  ActiveTripCard.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData
import Combine

struct ActiveTripCard: View {
    let trip: Trip
    let viewModel: HomeViewModel
    
    @Environment(\.modelContext) private var modelContext
    @State private var currentTime = Date()
    @State private var showingVehiclePicker = false
    @State private var availableVehicles: [Vehicle] = []
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.standardPadding) {
            // Header
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.accentColor)
                Text("Trip in Progress")
                    .font(.headline)
                Spacer()
            }
            
            // Vehicle Selection
            if !availableVehicles.isEmpty {
                Button {
                    showingVehiclePicker = true
                } label: {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.accentColor)
                        if let vehicle = trip.vehicle {
                            Text(vehicle.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Text("Select Vehicle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Stats Row
            HStack(spacing: AppConstants.standardPadding) {
                // Duration
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(durationText)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Distance
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.distanceMiles.formattedMiles)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            // Mini Map Placeholder (optional for MVP)
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 120)
                .overlay {
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Route Map")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            
            // Stop Button
            Button {
                Task {
                    await viewModel.stopTrip()
                }
            } label: {
                HStack {
                    if viewModel.isStoppingTrip {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Trip")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(AppConstants.cornerRadius)
            }
            .disabled(viewModel.isStoppingTrip)
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cornerRadius)
        .shadow(radius: AppConstants.cardShadowRadius)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            loadVehicles()
        }
        .sheet(isPresented: $showingVehiclePicker) {
            VehiclePickerSheet(
                vehicles: availableVehicles,
                selectedVehicle: trip.vehicle,
                onSelect: { vehicle in
                    trip.vehicle = vehicle
                    try? modelContext.save()
                }
            )
        }
    }
    
    private func loadVehicles() {
        let descriptor = FetchDescriptor<Vehicle>(
            sortBy: [SortDescriptor(\.name)]
        )
        availableVehicles = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Computes duration based on currentTime to trigger SwiftUI updates
    private var durationText: String {
        // Using currentTime ensures SwiftUI re-renders when timer fires
        let duration = currentTime.timeIntervalSince(trip.startTime)
        return duration.formattedDurationWithSeconds
    }
}

struct VehiclePickerSheet: View {
    let vehicles: [Vehicle]
    let selectedVehicle: Vehicle?
    let onSelect: (Vehicle?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Text("No Vehicle")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedVehicle == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                ForEach(vehicles) { vehicle in
                    Button {
                        onSelect(vehicle)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if let make = vehicle.make, let model = vehicle.model {
                                    Text("\(make) \(model)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if selectedVehicle?.id == vehicle.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext
    let viewModel = HomeViewModel(modelContext: context)
    
    ActiveTripCard(
        trip: Trip(startLatitude: 37.7749, startLongitude: -122.4194),
        viewModel: viewModel
    )
    .padding()
    .modelContainer(container)
}

