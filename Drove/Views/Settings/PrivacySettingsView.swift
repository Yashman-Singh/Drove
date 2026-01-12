//
//  PrivacySettingsView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import CoreLocation
import CoreMotion

struct PrivacySettingsView: View {
    @State private var viewModel: SettingsViewModel?
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var motionStatus: CMAuthorizationStatus = .notDetermined
    
    var body: some View {
        List {
            // Location Permission Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location")
                            .font(.headline)
                        Text(viewModel?.locationPermissionDescription ?? "Unknown")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if viewModel?.needsLocationPermission == true {
                        Button("Grant Permission") {
                            viewModel?.locationManager.requestAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                    } else if viewModel?.needsPermissionUpgrade == true {
                        Button("Upgrade to Always") {
                            viewModel?.locationManager.requestAuthorization()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                if viewModel?.needsLocationPermission == true {
                    Button {
                        viewModel?.openSystemSettings()
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                }
            } header: {
                Text("Location Permission")
            } footer: {
                Text("Drove needs 'Always' location permission to track trips in the background. Your location data is stored only on your device and never shared.")
            }
            
            // Motion Permission Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Motion & Fitness")
                            .font(.headline)
                        Text(motionStatusDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if motionStatus == .authorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Grant Permission") {
                            requestMotionPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Text("Motion Permission")
            } footer: {
                Text("Motion data helps Drove detect when you're driving versus walking, improving trip accuracy.")
            }
            
            // Privacy Information Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Privacy")
                        .font(.headline)
                    Text("All location and trip data is stored locally on your device. No data is transmitted to any server or shared with third parties.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Privacy")
            }
        }
        .navigationTitle("Privacy & Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(locationManager: LocationManager())
            }
            updatePermissionStatuses()
        }
        .onChange(of: viewModel?.locationPermissionStatus) { _, _ in
            updatePermissionStatuses()
        }
    }
    
    private var motionStatusDescription: String {
        switch motionStatus {
        case .notDetermined:
            return "Not determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func updatePermissionStatuses() {
        if let viewModel = viewModel {
            locationStatus = viewModel.locationPermissionStatus
        }
        
        motionStatus = CMMotionActivityManager.authorizationStatus()
    }
    
    private func requestMotionPermission() {
        let motionManager = CMMotionActivityManager()
        let queue = OperationQueue()
        
        motionManager.startActivityUpdates(to: queue) { _ in
            motionManager.stopActivityUpdates()
            DispatchQueue.main.async {
                motionStatus = CMMotionActivityManager.authorizationStatus()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
