//
//  BatteryProvider.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import Combine
import Foundation
import IOKit.ps

protocol BatteryMonitoring: AnyObject {
    var currentSnapshot: BatterySnapshot { get }
    var snapshotPublisher: AnyPublisher<BatterySnapshot, Never> { get }
    func refresh()
}

@MainActor
final class IOKitBatteryMonitor: ObservableObject, BatteryMonitoring {
    @Published private var snapshot = BatterySnapshot.unsupported

    var currentSnapshot: BatterySnapshot {
        snapshot
    }

    var snapshotPublisher: AnyPublisher<BatterySnapshot, Never> {
        $snapshot.eraseToAnyPublisher()
    }

    private var runLoopSource: CFRunLoopSource?
    private var workspaceObservers: [NSObjectProtocol] = []

    init() {
        snapshot = Self.readSnapshot()
        startMonitoring()
    }

    deinit {
        if let runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .defaultMode
            )
        }

        for observer in workspaceObservers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func refresh() {
        snapshot = Self.readSnapshot()
    }

    private func startMonitoring() {
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }

            let monitor = Unmanaged<IOKitBatteryMonitor>.fromOpaque(context)
                .takeUnretainedValue()
            Task { @MainActor in
                monitor.refresh()
            }
        }

        if let unmanagedSource = IOPSNotificationCreateRunLoopSource(
            callback,
            Unmanaged.passUnretained(self).toOpaque()
        ) {
            let source = unmanagedSource.takeRetainedValue()
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.refresh()
                }
            },
            workspaceCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.refresh()
                }
            },
        ]
    }

    private static func readSnapshot() -> BatterySnapshot {
        guard
            let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sourceList = IOPSCopyPowerSourcesList(info)?.takeRetainedValue()
                as? [CFTypeRef]
        else {
            return .unsupported
        }

        let internalDescriptions =
            sourceList
            .compactMap { source -> [String: Any]? in
                IOPSGetPowerSourceDescription(info, source)?
                    .takeUnretainedValue() as? [String: Any]
            }
            .filter { description in
                let transport =
                    description[kIOPSTransportTypeKey as String] as? String
                return transport == kIOPSInternalType
            }

        guard let description = internalDescriptions.first else {
            return .unsupported
        }

        let currentCapacity =
            description[kIOPSCurrentCapacityKey as String] as? Int
        let maxCapacity = description[kIOPSMaxCapacityKey as String] as? Int
        let isCharging =
            description[kIOPSIsChargingKey as String] as? Bool ?? false
        let powerSourceStateRaw =
            description[kIOPSPowerSourceStateKey as String] as? String
        let isCharged =
            description[kIOPSIsChargedKey as String] as? Bool ?? false
        let timeToEmpty = description[kIOPSTimeToEmptyKey as String] as? Int
        let timeToFullCharge =
            description[kIOPSTimeToFullChargeKey as String] as? Int

        let percentage: Int? = {
            guard let currentCapacity, let maxCapacity, maxCapacity > 0 else {
                return nil
            }

            let ratio = Double(currentCapacity) / Double(maxCapacity)
            return min(max(Int((ratio * 100).rounded()), 0), 100)
        }()

        let powerSourceState: BatterySnapshot.PowerSourceState = {
            if isCharged {
                return .charged
            }

            if isCharging {
                return .charging
            }

            if powerSourceStateRaw == kIOPSBatteryPowerValue {
                return .battery
            }

            if powerSourceStateRaw == kIOPSACPowerValue {
                return .pluggedIn
            }

            return .unknown
        }()

        return BatterySnapshot(
            chargePercent: percentage,
            isCharging: isCharging,
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            hasInternalBattery: true,
            powerSourceState: powerSourceState,
            minutesToEmpty: normalizedEstimate(timeToEmpty),
            minutesToFullCharge: normalizedEstimate(timeToFullCharge)
        )
    }

    private static func normalizedEstimate(_ value: Int?) -> Int? {
        guard let value, value >= 0 else {
            return nil
        }

        return value
    }
}
