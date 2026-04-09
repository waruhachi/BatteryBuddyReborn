//
//  AppCoordinator.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import Foundation

@MainActor
final class AppCoordinator {
    private let batteryMonitor: any BatteryMonitoring
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let updateChecker: any UpdateChecking
    private let aboutPresenter: any AboutPresenting
    private let formatter: any BatteryStatusFormatting

    private var statusItemCoordinator: StatusItemCoordinator?

    init(
        batteryMonitor: any BatteryMonitoring,
        launchAtLoginManager: any LaunchAtLoginManaging,
        updateChecker: any UpdateChecking,
        aboutPresenter: any AboutPresenting,
        formatter: any BatteryStatusFormatting
    ) {
        self.batteryMonitor = batteryMonitor
        self.launchAtLoginManager = launchAtLoginManager
        self.updateChecker = updateChecker
        self.aboutPresenter = aboutPresenter
        self.formatter = formatter
    }

    func start() {
        let registrationResult = launchAtLoginManager.ensureRegistered()
        if !registrationResult.succeeded {
            presentLaunchAtLoginFailure(
                message: registrationResult.errorMessage
            )
        }

        let model = MenuBarViewModel(
            batteryMonitor: batteryMonitor,
            formatter: formatter
        )
        let statusItemCoordinator = StatusItemCoordinator(
            model: model,
            updateChecker: updateChecker,
            aboutPresenter: aboutPresenter
        )
        self.statusItemCoordinator = statusItemCoordinator
        model.refresh()
    }

    private func presentLaunchAtLoginFailure(message: String?) {
        let alert = NSAlert()
        alert.messageText = "Unable to Enable Launch at Login"
        alert.informativeText =
            message
            ?? "BatteryBuddy couldn’t register itself to launch automatically at login."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
