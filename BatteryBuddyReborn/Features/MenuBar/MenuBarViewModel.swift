//
//  MenuBarViewModel.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import Combine
import Foundation

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var snapshot: BatterySnapshot
    @Published private(set) var statusImage: NSImage
    @Published private(set) var statusContent: BatteryStatusContent

    private let renderer = BuddyRenderer()
    private let batteryMonitor: any BatteryMonitoring
    private let formatter: any BatteryStatusFormatting
    private var cancellables: Set<AnyCancellable> = []

    init(
        batteryMonitor: any BatteryMonitoring,
        formatter: any BatteryStatusFormatting
    ) {
        self.batteryMonitor = batteryMonitor
        self.formatter = formatter
        let snapshot = batteryMonitor.currentSnapshot
        self.snapshot = snapshot
        self.statusImage = renderer.render(snapshot: snapshot)
        self.statusContent = formatter.makeContent(from: snapshot)

        batteryMonitor.snapshotPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                guard let self else { return }
                self.snapshot = snapshot
                self.statusImage = self.renderer.render(snapshot: snapshot)
                self.statusContent = self.formatter.makeContent(from: snapshot)
            }
            .store(in: &cancellables)
    }

    var headlineText: String {
        statusContent.headline
    }

    var detailText: String {
        statusContent.detail
    }

    func refresh() {
        batteryMonitor.refresh()
    }
}
