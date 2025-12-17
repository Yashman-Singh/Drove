//
//  TripCategory.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation

enum TripCategory: String, CaseIterable, Codable {
    case commute = "commute"
    case roadTrip = "road_trip"
    case errand = "errand"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .commute: return "Commute"
        case .roadTrip: return "Road Trip"
        case .errand: return "Errand"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .commute: return "briefcase.fill"
        case .roadTrip: return "car.fill"
        case .errand: return "basket.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}

