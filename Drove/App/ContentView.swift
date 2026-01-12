//
//  ContentView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var shouldStartTrip = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            PassportView()
                .tabItem {
                    Label("Passport", systemImage: "book.closed.fill")
                }
                .tag(1)
            
            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "list.bullet")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .environment(\.selectedTab, $selectedTab)
        .environment(\.shouldStartTrip, $shouldStartTrip)
    }
}

// Environment key for tab selection
private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

private struct ShouldStartTripKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var selectedTab: Binding<Int> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
    
    var shouldStartTrip: Binding<Bool> {
        get { self[ShouldStartTripKey.self] }
        set { self[ShouldStartTripKey.self] = newValue }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainerProvider.shared)
}
