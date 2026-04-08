//
//  AppServices.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import Foundation

protocol AboutPresenting {
    func presentAboutPanel()
}

@MainActor
final class StandardAboutPresenter: AboutPresenting {
    func presentAboutPanel() {
        NSApp.orderFrontStandardAboutPanel([
            NSApplication.AboutPanelOptionKey.applicationVersion: Bundle.main
                .infoDictionary?["CFBundleShortVersionString"] as? String
                ?? "1.0.3",
            NSApplication.AboutPanelOptionKey.version: Bundle.main
                .infoDictionary?["CFBundleVersion"] as? String ?? "11",
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}
