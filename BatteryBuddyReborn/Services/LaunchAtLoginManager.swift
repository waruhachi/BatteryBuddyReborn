//
//  LaunchAtLoginManager.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import Combine
import Foundation
import ServiceManagement

protocol LaunchAtLoginManaging {
    func ensureRegistered()
}

@MainActor
final class ServiceManagementLaunchAtLoginManager: ObservableObject,
    LaunchAtLoginManaging
{
    @Published private(set) var lastErrorMessage: String?

    func ensureRegistered() {
        guard SMAppService.mainApp.status != .enabled else {
            lastErrorMessage = nil
            return
        }

        do {
            try SMAppService.mainApp.register()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }
}
