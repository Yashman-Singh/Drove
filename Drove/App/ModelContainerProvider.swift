//
//  ModelContainerProvider.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation
import SwiftData

@MainActor
enum ModelContainerProvider {
    static let shared: ModelContainer = {
        let schema = Schema([Trip.self, Vehicle.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

