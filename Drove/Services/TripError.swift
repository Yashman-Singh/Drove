//
//  TripError.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation

enum TripError: LocalizedError {
    case tripAlreadyInProgress
    case noTripInProgress
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .tripAlreadyInProgress:
            return "A trip is already being recorded"
        case .noTripInProgress:
            return "No trip is currently in progress"
        case .locationUnavailable:
            #if targetEnvironment(simulator)
            return "Unable to get location. In the Simulator, go to Features → Location and select a simulated location."
            #else
            return "Unable to get current location. Please ensure Location Services are enabled and you have GPS signal."
            #endif
        }
    }
}

