//
//  DrivingPassportShortcuts.swift
//  Drove
//
//  Created by Yashman Singh on 12/17/25.
//

import AppIntents

struct DrivingPassportShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTripIntent(),
            phrases: [
                "Start a trip in \(.applicationName)",
                "Start driving with \(.applicationName)",
                "Start trip in \(.applicationName)"
            ],
            shortTitle: "Start Trip",
            systemImageName: "car.fill"
        )
        AppShortcut(
            intent: StopTripIntent(),
            phrases: [
                "Stop my trip in \(.applicationName)",
                "End driving with \(.applicationName)",
                "Stop trip in \(.applicationName)"
            ],
            shortTitle: "Stop Trip",
            systemImageName: "stop.circle.fill"
        )
    }
}
