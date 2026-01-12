//
//  VehiclesView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct VehiclesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: VehiclesViewModel?
    @State private var vehicles: [Vehicle] = []
    @State private var showingAddVehicle = false
    @State private var editingVehicle: Vehicle?
    @State private var showingDeleteConfirmation = false
    @State private var vehicleToDelete: Vehicle?
    @AppStorage(AppConstants.defaultVehicleIDKey) private var defaultVehicleIDString: String = ""
    
    var body: some View {
        List {
            if vehicles.isEmpty {
                ContentUnavailableView(
                    "No Vehicles",
                    systemImage: "car.fill",
                    description: Text("Add a vehicle to track trips by vehicle.")
                )
            } else {
                ForEach(vehicles) { vehicle in
                    VehicleRow(
                        vehicle: vehicle,
                        isDefault: defaultVehicleIDString == vehicle.id.uuidString,
                        onSetDefault: {
                            viewModel?.setDefaultVehicle(vehicle)
                            defaultVehicleIDString = vehicle.id.uuidString
                        },
                        onEdit: {
                            editingVehicle = vehicle
                        },
                        onDelete: {
                            vehicleToDelete = vehicle
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
        }
        .navigationTitle("Vehicles")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddVehicle = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            VehicleFormView(
                viewModel: viewModel,
                onSave: { name, make, model, year in
                    viewModel?.createVehicle(name: name, make: make, model: model, year: year)
                    loadVehicles()
                }
            )
        }
        .sheet(item: $editingVehicle) { vehicle in
            VehicleFormView(
                viewModel: viewModel,
                vehicle: vehicle,
                onSave: { name, make, model, year in
                    viewModel?.updateVehicle(vehicle, name: name, make: make, model: model, year: year)
                    loadVehicles()
                }
            )
        }
        .alert("Delete Vehicle?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                vehicleToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let vehicle = vehicleToDelete {
                    viewModel?.deleteVehicle(vehicle)
                    loadVehicles()
                    vehicleToDelete = nil
                }
            }
        } message: {
            if let vehicle = vehicleToDelete {
                Text("This will remove the vehicle from all associated trips. The trips will remain but won't be associated with a vehicle.")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = VehiclesViewModel(modelContext: modelContext)
            }
            loadVehicles()
        }
    }
    
    private func loadVehicles() {
        vehicles = viewModel?.fetchVehicles() ?? []
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle
    let isDefault: Bool
    let onSetDefault: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.name)
                        .font(.headline)
                    if isDefault {
                        Text("Default")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                if let make = vehicle.make, let model = vehicle.model {
                    Text("\(make) \(model)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let year = vehicle.year {
                    Text(String(year))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Menu {
                if !isDefault {
                    Button {
                        onSetDefault()
                    } label: {
                        Label("Set as Default", systemImage: "star.fill")
                    }
                }
                
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct VehicleFormView: View {
    let viewModel: VehiclesViewModel?
    var vehicle: Vehicle? = nil
    let onSave: (String, String?, String?, Int?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var yearString: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Vehicle Name", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Required")
                }
                
                Section {
                    TextField("Make", text: $make)
                        .textInputAutocapitalization(.words)
                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.words)
                    TextField("Year", text: $yearString)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Optional")
                } footer: {
                    Text("Additional details help you identify your vehicles.")
                }
            }
            .navigationTitle(vehicle == nil ? "Add Vehicle" : "Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let year = Int(yearString)
                        onSave(
                            name,
                            make.isEmpty ? nil : make,
                            model.isEmpty ? nil : model,
                            year
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let vehicle = vehicle {
                    name = vehicle.name
                    make = vehicle.make ?? ""
                    model = vehicle.model ?? ""
                    yearString = vehicle.year.map { String($0) } ?? ""
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VehiclesView()
    }
    .modelContainer(ModelContainerProvider.shared)
}
