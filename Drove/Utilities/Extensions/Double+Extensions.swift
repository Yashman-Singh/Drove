//
//  Double+Extensions.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation

extension Double {
    var formattedMiles: String {
        String(format: "%.1f mi", self)
    }
    
    var formattedKilometers: String {
        String(format: "%.1f km", self)
    }
    
    var formattedLargeNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
    }
    
    var formattedPercentage: String {
        String(format: "%.1f%%", self * 100)
    }
    
    func formattedRatio(numerator: Double, denominator: Double) -> String {
        "\(Int(numerator)) / \(Int(denominator))"
    }
}

extension TimeInterval {
    /// Formats duration as HH:MM:SS for active trips
    var formattedDurationWithSeconds: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formats duration as compact string for trip summaries (e.g., "2h 15m" or "45 min")
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
    
    /// Formats duration as days or hours (e.g., "6.5 days" or "156 hours")
    var formattedAsDays: String {
        let days = self / 86400
        if days >= 1 {
            return String(format: "%.1f days", days)
        }
        let hours = Int(self) / 3600
        return "\(hours) hours"
    }
    
    /// Formats duration as hours only
    var formattedAsHours: String {
        let hours = Int(self) / 3600
        return "\(hours) hours"
    }
}

