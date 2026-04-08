//
//  BatteryStatusFormatting.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import Foundation

struct BatteryStatusContent: Equatable {
    let headline: String
    let detail: String
}

protocol BatteryStatusFormatting {
    func makeContent(from snapshot: BatterySnapshot) -> BatteryStatusContent
}

struct BatteryStatusFormatter: BatteryStatusFormatting {
    func makeContent(from snapshot: BatterySnapshot) -> BatteryStatusContent {
        BatteryStatusContent(
            headline: headline(from: snapshot),
            detail: detail(from: snapshot)
        )
    }

    private func headline(from snapshot: BatterySnapshot) -> String {
        guard snapshot.hasInternalBattery,
            let chargePercent = snapshot.chargePercent
        else {
            return "Unknown"
        }

        return "\(chargePercent)%"
    }

    private func detail(from snapshot: BatterySnapshot) -> String {
        guard snapshot.hasInternalBattery else {
            return "Battery status unavailable"
        }

        switch snapshot.powerSourceState {
        case .charging:
            if let minutesToFullCharge = snapshot.minutesToFullCharge {
                return
                    "Charging - \(format(minutes: minutesToFullCharge)) until fully charged"
            }
            return "Charging"
        case .charged:
            return "Fully charged"
        case .battery:
            if let minutesToEmpty = snapshot.minutesToEmpty {
                return "\(format(minutes: minutesToEmpty)) remaining"
            }
            return "On battery"
        case .unknown:
            return snapshot.isCharging
                ? "Charging" : "Battery status unavailable"
        }
    }

    private func format(minutes: Int) -> String {
        let totalMinutes = max(minutes, 0)
        let hours = totalMinutes / 60
        let remainingMinutes = totalMinutes % 60

        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)m"
        }

        if hours > 0 {
            return "\(hours)h"
        }

        return "\(remainingMinutes)m"
    }
}
