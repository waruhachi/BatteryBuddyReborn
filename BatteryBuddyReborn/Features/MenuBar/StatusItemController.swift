//
//  StatusItemController.swift
//  BatteryBuddyReborn
//
//  Created by waru on 4/8/26.
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemCoordinator: NSObject {
    private let model: MenuBarViewModel
    private let updateChecker: any UpdateChecking
    private let aboutPresenter: any AboutPresenting
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let menu: NSMenu
    private var cancellables: Set<AnyCancellable> = []
    private var eventMonitor: Any?

    init(
        model: MenuBarViewModel,
        updateChecker: any UpdateChecking,
        aboutPresenter: any AboutPresenting
    ) {
        self.model = model
        self.updateChecker = updateChecker
        self.aboutPresenter = aboutPresenter
        self.statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        self.popover = NSPopover()
        self.menu = NSMenu()
        super.init()

        configurePopover()
        configureStatusItem()
        configureMenu()
        bindModel()
    }

    deinit {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        let hostingController = NSHostingController(
            rootView: MenuBarContentView(model: model)
        )
        hostingController.view.frame.size = NSSize(width: 190, height: 74)
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 190, height: 74)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.imagePosition = .imageOnly
        button.image = model.statusImage
        button.action = #selector(handleStatusItemClick(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configureMenu() {
        let aboutItem = NSMenuItem(
            title: "About",
            action: #selector(showAboutPanel),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        let updateItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func bindModel() {
        model.$statusImage
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                self?.statusItem.button?.image = image
            }
            .store(in: &cancellables)
    }

    @objc
    private func handleStatusItemClick(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent, let button = statusItem.button
        else {
            return
        }

        switch event.type {
        case .rightMouseUp:
            if popover.isShown {
                popover.performClose(nil)
                removeEventMonitor()
            }
            statusItem.menu = menu
            button.performClick(nil)
            statusItem.menu = nil
        default:
            togglePopover(relativeTo: button)
        }
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
            removeEventMonitor()
            return
        }

        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        startEventMonitor()
    }

    private func startEventMonitor() {
        removeEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown, .rightMouseDown,
        ]) { [weak self] _ in
            Task { @MainActor in
                self?.popover.performClose(nil)
                self?.removeEventMonitor()
            }
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    @objc
    private func showAboutPanel() {
        aboutPresenter.presentAboutPanel()
    }

    @objc
    private func checkForUpdates() {
        updateChecker.checkForUpdates()
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}
