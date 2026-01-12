//
//  EmptyStateView.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: AppConstants.standardPadding) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConstants.standardPadding * 2)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppConstants.standardPadding)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.cornerRadius)
                }
                .padding(.horizontal, AppConstants.standardPadding * 2)
                .padding(.top, AppConstants.standardPadding)
            }
        }
        .padding(AppConstants.standardPadding * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "car.fill",
        title: "No trips yet",
        description: "Start your first trip to begin building your driving passport",
        actionTitle: "Start Trip",
        action: {}
    )
}
