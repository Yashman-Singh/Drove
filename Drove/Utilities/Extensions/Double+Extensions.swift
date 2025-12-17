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
}

extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }
}

