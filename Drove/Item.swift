//
//  Item.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
