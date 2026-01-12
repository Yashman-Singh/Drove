//
//  StatCard.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var subtitle: String? = nil
    var color: Color? = nil
    var inlineSubtitle: (main: String, secondary: String)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color ?? .accentColor)
                Spacer()
            }
            
            if let inline = inlineSubtitle {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(inline.main)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(inline.secondary)
                        .font(.title3)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppConstants.standardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(AppConstants.cornerRadius)
    }
}

#Preview {
    HStack {
        StatCard(
            title: "Total Miles",
            value: "12,456",
            icon: "mappin.circle.fill"
        )
        
        StatCard(
            title: "States Visited",
            value: "",
            icon: "map.fill",
            inlineSubtitle: (main: "12", secondary: " / 50")
        )
    }
    .padding()
}
