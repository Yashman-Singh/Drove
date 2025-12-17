//
//  ContentView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            PassportView()
                .tabItem {
                    Label("Passport", systemImage: "book.closed.fill")
                }
            
            TripsListView()
                .tabItem {
                    Label("Trips", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainerProvider.shared)
}
