//
//  StatesMapView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct StatesMapView: View {
    let viewModel: PassportViewModel
    
    private let allUSStates = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ]
    
    private var visitedStates: Set<String> {
        viewModel.statesVisited
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.standardPadding) {
            HStack {
                Text("States Visited")
                    .font(.headline)
                Spacer()
                Text("\(visitedStates.count) / 50")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allUSStates, id: \.self) { state in
                        StateBadge(
                            state: state,
                            isVisited: visitedStates.contains(state)
                        )
                    }
                }
                .padding(.horizontal, AppConstants.standardPadding)
            }
        }
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
}

struct StateBadge: View {
    let state: String
    let isVisited: Bool
    
    var body: some View {
        Text(state)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(isVisited ? .white : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isVisited ? Color.accentColor : Color(.systemGray5))
            .cornerRadius(8)
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext
    
    let viewModel = PassportViewModel(modelContext: context)
    
    return StatesMapView(viewModel: viewModel)
        .padding()
        .modelContainer(container)
}
