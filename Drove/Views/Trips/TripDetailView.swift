//
//  TripDetailView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData
import MapKit

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let trip: Trip
    
    @State private var isEditingNotes = false
    @State private var editedNotes: String = ""
    @State private var showCategoryPicker = false
    @State private var showVehiclePicker = false
    @State private var showDeleteConfirmation = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String?
    @State private var availableVehicles: [Vehicle] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppConstants.standardPadding) {
                // Map Section
                TripMapView(trip: trip)
                    .frame(height: 300)
                    .cornerRadius(AppConstants.cornerRadius)
                    .padding(.horizontal, AppConstants.standardPadding)
                
                // Summary Card
                summaryCard
                    .padding(.horizontal, AppConstants.standardPadding)
                
                // Locations Section
                locationsSection
                    .padding(.horizontal, AppConstants.standardPadding)
                
                // Notes Section
                notesSection
                    .padding(.horizontal, AppConstants.standardPadding)
                
                // Actions Section
                actionsSection
                    .padding(.horizontal, AppConstants.standardPadding)
                    .padding(.bottom, AppConstants.standardPadding)
            }
            .padding(.vertical, AppConstants.standardPadding)
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditingNotes {
                    Button("Save") {
                        saveNotes()
                    }
                } else {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Trip", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            categoryPickerSheet
        }
        .sheet(isPresented: $showVehiclePicker) {
            vehiclePickerSheet
        }
        .onAppear {
            editedNotes = trip.notes ?? ""
            loadVehicles()
        }
        .alert("Delete Trip?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    private var summaryCard: some View {
        VStack(spacing: AppConstants.standardPadding) {
            HStack {
                Text("Summary")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: AppConstants.standardPadding) {
                // Distance
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.distanceMiles.formattedMiles)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Duration
                VStack(alignment: .center, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.durationSeconds.formattedDuration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Category
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon)
                            .font(.caption)
                        Text(categoryName)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Divider()
            
            // Vehicle (if assigned)
            if let vehicle = trip.vehicle {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.accentColor)
                    Text(vehicle.name)
                        .font(.subheadline)
                    if let make = vehicle.make, let model = vehicle.model {
                        Text("• \(make) \(model)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            // Date/Time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trip.startTime.shortDate)
                        .font(.subheadline)
                }
                
                Spacer()
                
                if let endTime = trip.endTime {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(trip.startTime.timeOnly) - \(endTime.timeOnly)")
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
    
    private var locationsSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.standardPadding) {
            Text("Locations")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Start Location
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.green)
                        Text("Start")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    if let address = trip.startAddress {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(String(format: "%.4f", trip.startLatitude)), \(String(format: "%.4f", trip.startLongitude))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // End Location
                if let endLat = trip.endLatitude, let endLng = trip.endLongitude {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text("End")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        if let address = trip.endAddress {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(String(format: "%.4f", endLat)), \(String(format: "%.4f", endLng))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppConstants.standardPadding) {
            Text("Notes")
                .font(.headline)
            
            if isEditingNotes {
                TextEditor(text: $editedNotes)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                HStack {
                    Button("Cancel") {
                        editedNotes = trip.notes ?? ""
                        isEditingNotes = false
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveNotes()
                    }
                    .fontWeight(.semibold)
                }
            } else {
                Group {
                    if let notes = trip.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack {
                            Text("Tap to add notes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                            Spacer()
                        }
                    }
                }
                .frame(height: 60, alignment: .top)
                .contentShape(Rectangle())
                .onTapGesture {
                    isEditingNotes = true
                }
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
    
    private var actionsSection: some View {
        VStack(spacing: AppConstants.standardPadding) {
            // Edit Category
            Button {
                showCategoryPicker = true
            } label: {
                HStack {
                    Image(systemName: "tag.fill")
                    Text("Edit Category")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(AppConstants.standardPadding)
                .background(Color(.systemGray6))
                .cornerRadius(AppConstants.cornerRadius)
            }
            
            // Edit Vehicle
            if !availableVehicles.isEmpty {
                Button {
                    showVehiclePicker = true
                } label: {
                    HStack {
                        Image(systemName: "car.fill")
                        Text("Edit Vehicle")
                        Spacer()
                        HStack(spacing: 4) {
                            if let vehicle = trip.vehicle {
                                Text(vehicle.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("None")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(AppConstants.standardPadding)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppConstants.cornerRadius)
                }
            }
            
            // Toggle Favorite
            Button {
                toggleFavorite()
            } label: {
                HStack {
                    Image(systemName: trip.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(trip.isFavorite ? .red : .secondary)
                    Text(trip.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                    Spacer()
                }
                .padding(AppConstants.standardPadding)
                .background(Color(.systemGray6))
                .cornerRadius(AppConstants.cornerRadius)
            }
        }
    }
    
    private var categoryPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(TripCategory.allCases, id: \.self) { category in
                    Button {
                        updateCategory(category)
                    } label: {
                        HStack {
                            Image(systemName: category.iconName)
                                .foregroundColor(.accentColor)
                            Text(category.displayName)
                            Spacer()
                            if trip.category == category.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showCategoryPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Computed Properties
    
    private var categoryIcon: String {
        TripCategory(rawValue: trip.category)?.iconName ?? TripCategory.other.iconName
    }
    
    private var categoryName: String {
        TripCategory(rawValue: trip.category)?.displayName ?? TripCategory.other.displayName
    }
    
    // MARK: - Actions
    
    private func saveNotes() {
        trip.notes = editedNotes.isEmpty ? nil : editedNotes
        saveContext()
        isEditingNotes = false
    }
    
    private func updateCategory(_ category: TripCategory) {
        trip.category = category.rawValue
        saveContext()
        showCategoryPicker = false
    }
    
    private func toggleFavorite() {
        trip.isFavorite.toggle()
        saveContext()
    }
    
    private func deleteTrip() {
        modelContext.delete(trip)
        saveContext()
        dismiss()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func loadVehicles() {
        let descriptor = FetchDescriptor<Vehicle>(
            sortBy: [SortDescriptor(\.name)]
        )
        availableVehicles = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private var vehiclePickerSheet: some View {
        NavigationStack {
            List {
                Button {
                    trip.vehicle = nil
                    saveContext()
                    showVehiclePicker = false
                } label: {
                    HStack {
                        Text("No Vehicle")
                            .foregroundColor(.primary)
                        Spacer()
                        if trip.vehicle == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                ForEach(availableVehicles) { vehicle in
                    Button {
                        trip.vehicle = vehicle
                        saveContext()
                        showVehiclePicker = false
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
                            if trip.vehicle?.id == vehicle.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showVehiclePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    
    let trip = Trip(startLatitude: 37.7749, startLongitude: -122.4194)
    trip.endLatitude = 34.0522
    trip.endLongitude = -118.2437
    trip.startCity = "San Francisco"
    trip.endCity = "Los Angeles"
    trip.startAddress = "San Francisco, CA"
    trip.endAddress = "Los Angeles, CA"
    trip.distanceMeters = 560000
    trip.endTime = Date().addingTimeInterval(-3600)
    trip.category = TripCategory.roadTrip.rawValue
    trip.notes = "Great road trip!"
    
    var coords: [CLLocationCoordinate2D] = []
    coords.append(CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
    coords.append(CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437))
    trip.setRouteCoordinates(coords)
    
    return NavigationStack {
        TripDetailView(trip: trip)
    }
    .modelContainer(container)
}
