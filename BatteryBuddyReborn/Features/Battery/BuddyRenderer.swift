//
//  BuddyRenderer.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import Foundation

struct BuddyRenderer {
    func render(snapshot: BatterySnapshot) -> NSImage {
        let appearance = BuddyAppearance.from(snapshot: snapshot)
        let iconSize = canvasSize(for: appearance)
        let image = NSImage(size: iconSize)
        image.isTemplate = appearance.tintAsTemplate

        image.lockFocus()
        defer { image.unlockFocus() }

        NSGraphicsContext.current?.imageInterpolation = .high
        let batteryRect = batteryRect(for: appearance)

        drawFill(
            for: snapshot,
            in: batteryRect
        )

        drawMood(
            in: batteryRect,
            appearance: appearance
        )

        if let plugAssetName = appearance.plugAssetName {
            drawPlug(
                named: plugAssetName,
                in: plugRect(for: appearance)
            )
        }

        return image
    }

    private func drawFill(for snapshot: BatterySnapshot, in batteryRect: NSRect)
    {
        guard snapshot.hasInternalBattery,
            let chargePercent = snapshot.chargePercent
        else {
            return
        }

        let clampedPercent = min(max(CGFloat(chargePercent) / 100, 0), 1)
        let minimumVisibleWidth: CGFloat = chargePercent > 0 ? 1.5 : 0
        let maxFillWidth: CGFloat = 18
        let fillWidth = max(minimumVisibleWidth, maxFillWidth * clampedPercent)
        guard fillWidth > 0 else { return }

        let fillRect = NSRect(
            x: batteryRect.minX + 2,
            y: batteryRect.minY + 2,
            width: min(fillWidth, maxFillWidth),
            height: 8
        )
        let fillPath = NSBezierPath(
            roundedRect: fillRect,
            xRadius: 2,
            yRadius: 2
        )

        let fillColor: NSColor
        if chargePercent < 20 {
            fillColor = NSColor.systemRed.withAlphaComponent(0.9)
        } else if snapshot.isLowPowerMode {
            fillColor = NSColor.labelColor.withAlphaComponent(0.2)
        } else {
            fillColor = NSColor.labelColor.withAlphaComponent(0.25)
        }
        fillColor.setFill()
        fillPath.fill()
    }

    private func drawMood(in rect: NSRect, appearance: BuddyAppearance) {
        guard let moodImage = image(named: appearance.mood.assetName) else {
            return
        }
        moodImage.draw(
            in: rect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }

    private func drawPlug(named assetName: String, in rect: NSRect) {
        guard let chargerImage = image(named: assetName) else { return }

        chargerImage.draw(
            in: rect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }

    private func image(named name: String) -> NSImage? {
        guard let image = NSImage(named: name) else {
            return nil
        }

        image.isTemplate = true
        return image
    }

    private func canvasSize(for appearance: BuddyAppearance) -> NSSize {
        let assetName =
            appearance.plugAssetName == nil ? "MinimumWidth" : "MaximumWidth"
        return image(named: assetName)?.size
            ?? NSSize(
                width: appearance.iconSize.width,
                height: appearance.iconSize.height
            )
    }

    private func batteryRect(for appearance: BuddyAppearance) -> NSRect {
        let originX: CGFloat = appearance.plugAssetName == nil ? 0 : 6
        return NSRect(
            x: originX,
            y: 0,
            width: 25,
            height: 12
        )
    }

    private func plugRect(for appearance: BuddyAppearance) -> NSRect {
        NSRect(
            x: 0,
            y: 2,
            width: 5,
            height: 8
        )
    }
}

extension BuddyMood {
    fileprivate var assetName: String {
        switch self {
        case .sad:
            return "Sad"
        case .neutral:
            return "Neutral"
        case .happy:
            return "Happy"
        case .unknown:
            return "Unknown"
        }
    }
}
