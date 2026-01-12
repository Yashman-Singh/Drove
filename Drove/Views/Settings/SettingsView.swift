//
//  SettingsView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel?
    @State private var showDeleteTripsConfirmation = false
    @State private var showDeleteVehiclesConfirmation = false
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Vehicle Management Section
                Section {
                    NavigationLink {
                        VehiclesView()
                    } label: {
                        Label("Vehicles", systemImage: "car.fill")
                    }
                } header: {
                    Text("Vehicle Management")
                } footer: {
                    Text("Manage your vehicles and set a default vehicle for new trips.")
                }
                
                // Privacy & Permissions Section
                Section {
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Privacy & Permissions", systemImage: "lock.shield.fill")
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Manage location and motion permissions.")
                }
                
                // Data Management Section
                Section {
                    Button(role: .destructive) {
                        showDeleteTripsConfirmation = true
                    } label: {
                        Label("Delete All Trips", systemImage: "trash")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteVehiclesConfirmation = true
                    } label: {
                        Label("Delete All Vehicles", systemImage: "car.slash")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash.fill")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Permanently delete your trips, vehicles, or all data. This action cannot be undone.")
                }
                
                // App Information Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Drove - Your driving passport")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(locationManager: LocationManager())
                }
            }
            .alert("Delete All Trips", isPresented: $showDeleteTripsConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllTrips()
                }
            } message: {
                Text("Are you sure you want to delete all trips? This action cannot be undone.")
            }
            .alert("Delete All Vehicles", isPresented: $showDeleteVehiclesConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllVehicles()
                }
            } message: {
                Text("Are you sure you want to delete all vehicles? This will also remove vehicle assignments from trips. This action cannot be undone.")
            }
            .alert("Delete All Data", isPresented: $showDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Are you sure you want to delete all trips and vehicles? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
    
    private func deleteAllTrips() {
        guard let viewModel = viewModel else { return }
        do {
            try viewModel.deleteAllTrips(context: modelContext)
        } catch {
            deleteErrorMessage = "Failed to delete trips: \(error.localizedDescription)"
            showDeleteError = true
        }
    }
    
    private func deleteAllVehicles() {
        guard let viewModel = viewModel else { return }
        do {
            try viewModel.deleteAllVehicles(context: modelContext)
        } catch {
            deleteErrorMessage = "Failed to delete vehicles: \(error.localizedDescription)"
            showDeleteError = true
        }
    }
    
    private func deleteAllData() {
        guard let viewModel = viewModel else { return }
        do {
            try viewModel.deleteAllData(context: modelContext)
        } catch {
            deleteErrorMessage = "Failed to delete data: \(error.localizedDescription)"
            showDeleteError = true
        }
    }
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
}

#Preview {
    SettingsView()
        .modelContainer(ModelContainerProvider.shared)
}
