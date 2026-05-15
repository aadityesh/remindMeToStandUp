import AppKit
import Combine
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var hostingController: NSHostingController<SettingsView>?
    private var reminderController: ReminderWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()

        TimerManager.shared.onReminder = { [weak self] type in
            DispatchQueue.main.async { self?.showReminder(type: type) }
        }

        // Two-phase expand/collapse: NSPopover is the sole source of truth for size.
        // SwiftUI content just fills whatever the popover currently is (autoresizingMask).
        TimerManager.shared.$isExpanded
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] expanded in
                if expanded {
                    // 1. Grow window first
                    self?.animatePopoverSize(to: NSSize(width: 420, height: 580))
                    // 2. Only reveal extra content after resize finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            TimerManager.shared.showExpandedContent = true
                        }
                    }
                } else {
                    // 1. Hide extra content immediately
                    TimerManager.shared.showExpandedContent = false
                    // 2. Shrink window after content is gone
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        self?.animatePopoverSize(to: NSSize(width: 300, height: 460))
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "figure.stand.line.dotted.figure.stand",
                                   accessibilityDescription: "Standup")
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleStatusItemClick)
            button.target = self
        }

        let hc = NSHostingController(rootView: SettingsView())
        // SwiftUI view fills whatever size the popover gives it — no fixed frame needed
        hc.view.autoresizingMask = [.width, .height]
        hostingController = hc

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 300, height: 460)
        pop.behavior = .transient
        pop.delegate = self
        pop.contentViewController = hc
        popover = pop
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit Standup",
                                    action: #selector(NSApplication.terminate(_:)),
                                    keyEquivalent: "q"))
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // Timer-driven cubic ease-in-out resize — NSPopover is the single size authority
    private func animatePopoverSize(to target: NSSize) {
        guard let popover else { return }
        let start = popover.contentSize
        guard start != target else { return }
        let steps = 28
        let interval: TimeInterval = 0.38 / Double(steps)
        var step = 0

        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak popover] timer in
            step += 1
            let t = Double(step) / Double(steps)
            let ease = t < 0.5 ? 4*t*t*t : 1 - pow(-2*t+2, 3)/2
            let w = start.width  + (target.width  - start.width)  * ease
            let h = start.height + (target.height - start.height) * ease
            popover?.contentSize = NSSize(width: w, height: h)
            if step >= steps {
                timer.invalidate()
                popover?.contentSize = target
            }
        }
    }

    // MARK: - Reminder window

    private func showReminder(type: ReminderType) {
        reminderController?.dismissAnimated()
        reminderController = ReminderWindowController(type: type)
        reminderController?.showWindow(nil)
    }
}

// MARK: - Popover delegate

extension AppDelegate: NSPopoverDelegate {
    func popoverWillClose(_ notification: Notification) {
        // Reset both states so the panel reopens compact
        TimerManager.shared.showExpandedContent = false
        TimerManager.shared.isExpanded = false
        popover?.contentSize = NSSize(width: 300, height: 460)
    }
}
