//
//  Constants.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import SwiftUI

enum AppConstants {
    // MARK: - Trip Filtering
    static let minimumTripDistanceMeters: Double = 804.67 // 0.5 miles
    static let autoStopStationaryMinutes: Double = 5
    
    // MARK: - Location
    static let locationDistanceFilter: Double = 10 // meters
    static let minimumLocationAccuracy: Double = 50 // meters
    
    // MARK: - Earth
    static let earthCircumferenceMiles: Double = 24901
    
    // MARK: - UI
    static let cornerRadius: CGFloat = 12
    static let standardPadding: CGFloat = 16
    static let cardShadowRadius: CGFloat = 4
    
    // MARK: - Animation
    static let standardAnimation: Animation = .easeInOut(duration: 0.3)
    
    // MARK: - User Preferences
    static let defaultVehicleIDKey = "defaultVehicleID"
}

enum Milestones {
    static let distanceMilestones: [Double] = [1000, 5000, 10000, 25000, 50000, 100000]
    static let stateMilestones: [Int] = [10, 25, 50]
    static let tripMilestones: [Int] = [100, 500, 1000]
    
    // Fun comparisons
    static let moonDistanceMiles: Double = 238900
    static let marsDistanceMiles: Double = 33900000
}

