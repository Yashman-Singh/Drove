//
//  MilestoneCard.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI
import SwiftData

struct MilestoneCard: View {
    let viewModel: PassportViewModel
    
    var body: some View {
        if let milestone = viewModel.nextMilestone() {
            VStack(alignment: .leading, spacing: AppConstants.standardPadding) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.accentColor)
                    Text("Next Milestone")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(milestoneTypeDescription(milestone.type))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(milestone.current)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("of")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(milestone.target)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: geometry.size.width * min(milestone.progress, 1.0), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    Text(encouragementMessage(milestone.progress))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(AppConstants.standardPadding)
            .background(Color(.systemGray6))
            .cornerRadius(AppConstants.cornerRadius)
        }
    }
    
    private func milestoneTypeDescription(_ type: String) -> String {
        switch type {
        case "Distance":
            return "Distance Milestone"
        case "States":
            return "States Visited Milestone"
        case "Trips":
            return "Trips Milestone"
        default:
            return "Milestone"
        }
    }
    
    private func encouragementMessage(_ progress: Double) -> String {
        if progress >= 0.9 {
            return "Almost there! Keep going!"
        } else if progress >= 0.5 {
            return "You're halfway there!"
        } else if progress >= 0.25 {
            return "Great progress so far!"
        } else {
            return "Every trip counts!"
        }
    }
}

#Preview {
    let schema = Schema([Trip.self, Vehicle.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = container.mainContext
    
    let viewModel = PassportViewModel(modelContext: context)
    
    return MilestoneCard(viewModel: viewModel)
        .padding()
        .modelContainer(container)
}
