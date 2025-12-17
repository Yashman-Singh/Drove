//
//  Vehicle.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID
    var name: String
    var make: String?
    var model: String?
    var year: Int?
    var isActive: Bool
    var createdAt: Date
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isActive = true
        self.createdAt = Date()
    }
}

