import SwiftUI
import AppKit

@main
struct ThingsTodayPanelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingPanel: FloatingPanelWindow?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for a cleaner experience
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item (optional - can be hidden)
        setupMenuBar()

        // Create and show the floating panel
        showFloatingPanel()

        // Set up global hotkey listener (Option + T)
        setupGlobalHotkey()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use Things-style checkmark icon
            button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Things Today")
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    @objc func togglePanel() {
        if let panel = floatingPanel {
            if panel.isVisible {
                panel.orderOut(nil)
            } else {
                showFloatingPanel()
            }
        } else {
            showFloatingPanel()
        }
    }

    func showFloatingPanel() {
        if floatingPanel == nil {
            floatingPanel = FloatingPanelWindow()
        }

        floatingPanel?.makeKeyAndOrderFront(nil)
        floatingPanel?.center()

        // Restore saved position if available
        if let savedFrame = UserDefaults.standard.string(forKey: "panelFrame") {
            if let frame = NSRectFromString(savedFrame) as NSRect? {
                floatingPanel?.setFrame(frame, display: true)
            }
        }
    }

    func setupGlobalHotkey() {
        // Register Option+T hotkey
        // This would require Carbon or a third-party library like KeyboardShortcuts
        // For now, users can trigger via menu bar or Raycast
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save window position
        if let frame = floatingPanel?.frame {
            UserDefaults.standard.set(NSStringFromRect(frame), forKey: "panelFrame")
        }
    }
}
