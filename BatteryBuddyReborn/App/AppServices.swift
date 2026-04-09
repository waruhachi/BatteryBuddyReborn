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
            NSApplication.AboutPanelOptionKey.applicationVersion: bundleValue(
                for: "CFBundleShortVersionString"
            ),
            NSApplication.AboutPanelOptionKey.version: bundleValue(
                for: "CFBundleVersion"
            ),
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    private func bundleValue(for key: String) -> String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        else {
            return "Unknown"
        }

        let trimmedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedValue.isEmpty ? "Unknown" : trimmedValue
    }
}
