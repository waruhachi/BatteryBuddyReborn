//
//  BatteryBuddyRebornApp.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import SwiftUI

@main
struct BatteryBuddyRebornApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var appCoordinator = AppCoordinator(
        batteryMonitor: IOKitBatteryMonitor(),
        launchAtLoginManager: ServiceManagementLaunchAtLoginManager(),
        updateChecker: GitHubReleaseUpdateChecker(),
        aboutPresenter: StandardAboutPresenter(),
        formatter: BatteryStatusFormatter()
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        appCoordinator.start()
    }
}
