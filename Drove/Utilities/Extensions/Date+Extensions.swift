//
//  Date+Extensions.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import Foundation

extension Date {
    var shortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }
    
    var timeOnly: String {
        formatted(date: .omitted, time: .shortened)
    }
}

