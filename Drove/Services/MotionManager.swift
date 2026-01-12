//
//  MotionManager.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import CoreMotion
import Observation

@Observable
final class MotionManager {
    var isAutomotiveActivity: Bool = false
    
    var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }
    
    private let motionManager = CMMotionActivityManager()
    private let queue = OperationQueue()
    
    func startMonitoring() {
        guard isAvailable else { return }
        
        motionManager.startActivityUpdates(to: queue) { [weak self] activity in
            guard let activity = activity else { return }
            DispatchQueue.main.async {
                self?.isAutomotiveActivity = activity.automotive
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopActivityUpdates()
    }
}

