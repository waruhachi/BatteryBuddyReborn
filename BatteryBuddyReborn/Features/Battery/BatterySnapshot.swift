//
//  BatterySnapshot.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import Foundation

struct BatterySnapshot: Equatable {
    enum PowerSourceState: String, Equatable {
        case battery
        case charging
        case charged
        case unknown
    }

    static let unsupported = BatterySnapshot(
        chargePercent: nil,
        isCharging: false,
        isLowPowerMode: false,
        hasInternalBattery: false,
        powerSourceState: .unknown,
        minutesToEmpty: nil,
        minutesToFullCharge: nil
    )

    let chargePercent: Int?
    let isCharging: Bool
    let isLowPowerMode: Bool
    let hasInternalBattery: Bool
    let powerSourceState: PowerSourceState
    let minutesToEmpty: Int?
    let minutesToFullCharge: Int?
}

enum BuddyMood: String {
    case sad
    case neutral
    case happy
    case unknown
}

struct BuddyAppearance: Equatable {
    let mood: BuddyMood
    let plugAssetName: String?
    let tintAsTemplate: Bool
    let iconSize: CGSize

    static func from(snapshot: BatterySnapshot) -> BuddyAppearance {
        let mood: BuddyMood

        if !snapshot.hasInternalBattery || snapshot.chargePercent == nil {
            mood = .unknown
        } else if snapshot.isCharging {
            mood = .happy
        } else if let percent = snapshot.chargePercent {
            switch percent {
            case ..<21:
                mood = .sad
            case ..<50:
                mood = .neutral
            default:
                mood = .happy
            }
        } else {
            mood = .neutral
        }

        let plugAssetName: String?
        switch snapshot.powerSourceState {
        case .charging:
            plugAssetName = "PlugCharging"
        case .charged:
            plugAssetName = "PlugNotCharging"
        case .battery, .unknown:
            plugAssetName = nil
        }

        return BuddyAppearance(
            mood: mood,
            plugAssetName: plugAssetName,
            tintAsTemplate: true,
            iconSize: plugAssetName == nil
                ? CGSize(width: 25, height: 12) : CGSize(width: 31, height: 12)
        )
    }
}
