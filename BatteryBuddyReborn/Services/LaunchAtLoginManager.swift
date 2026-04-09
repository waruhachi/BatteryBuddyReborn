//
//  LaunchAtLoginManager.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import Foundation
import OSLog
import ServiceManagement

struct LaunchAtLoginRegistrationResult {
    let succeeded: Bool
    let errorMessage: String?

    static let success = LaunchAtLoginRegistrationResult(
        succeeded: true,
        errorMessage: nil
    )
}

protocol LaunchAtLoginManaging {
    func ensureRegistered() -> LaunchAtLoginRegistrationResult
}

@MainActor
final class ServiceManagementLaunchAtLoginManager: LaunchAtLoginManaging {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "BatteryBuddyReborn",
        category: "LaunchAtLogin"
    )

    func ensureRegistered() -> LaunchAtLoginRegistrationResult {
        guard SMAppService.mainApp.status != .enabled else {
            return .success
        }

        do {
            try SMAppService.mainApp.register()
            return .success
        } catch {
            let message = error.localizedDescription
            logger.error(
                "Failed to register launch at login: \(message, privacy: .public)"
            )
            return LaunchAtLoginRegistrationResult(
                succeeded: false,
                errorMessage: message
            )
        }
    }
}
