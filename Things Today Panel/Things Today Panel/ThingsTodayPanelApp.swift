import SwiftUI
import AppKit
import Carbon

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
    var onboardingWindow: NSWindow?
    var statusItem: NSStatusItem?
    var hotkeyEventHandler: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for a cleaner experience
        NSApp.setActivationPolicy(.accessory)

        // Create menu bar item with star icon
        setupMenuBar()

        // Check if first launch - show onboarding
        if !UserDefaults.standard.hasCompletedOnboarding {
            showOnboarding()
        } else {
            // Create and show the floating panel
            showFloatingPanel()
        }

        // Set up global hotkey (Command + Shift + T)
        setupGlobalHotkey()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Create custom star icon for menu bar
            let starImage = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Things Today")
            starImage?.size = NSSize(width: 16, height: 16)

            button.image = starImage
            button.action = #selector(togglePanel)
            button.target = self
            button.toolTip = "Things Today Panel (⌘⇧T)"
        }

        // Create menu
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Show Panel", action: #selector(showPanelFromMenu), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func showOnboarding() {
        let onboardingView = OnboardingView(isPresented: .constant(true))

        let hostingController = NSHostingController(rootView: onboardingView)
        onboardingWindow = NSWindow(contentViewController: hostingController)

        onboardingWindow?.styleMask = [.titled, .closable]
        onboardingWindow?.title = "Welcome"
        onboardingWindow?.center()
        onboardingWindow?.makeKeyAndOrderFront(nil)
        onboardingWindow?.level = .floating

        // When onboarding closes, show main panel
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: onboardingWindow,
            queue: .main
        ) { [weak self] _ in
            self?.showFloatingPanel()
        }
    }

    @objc func showPanelFromMenu() {
        showFloatingPanel()
    }

    @objc func openSettings() {
        // Show settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable]
        window.title = "Settings"
        window.center()
        window.makeKeyAndOrderFront(nil)
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
        // Register Command+Shift+T hotkey using Carbon
        var hotKeyRef: EventHotKeyRef?
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 17 // T key

        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.signature = OSType("htk1".fourCharCodeValue)
        gMyHotKeyID.id = 1

        var eventSpec = EventTypeSpec()
        eventSpec.eventClass = OSType(kEventClassKeyboard)
        eventSpec.eventKind = OSType(kEventHotKeyPressed)

        // Install event handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                // Toggle panel when hotkey is pressed
                if let appDelegate = userData?.assumingMemoryBound(to: AppDelegate.self).pointee {
                    DispatchQueue.main.async {
                        appDelegate.togglePanel()
                    }
                }
                return noErr
            },
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &hotkeyEventHandler
        )

        // Register hotkey
        RegisterEventHotKey(
            keyCode,
            modifiers,
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save window position
        if let frame = floatingPanel?.frame {
            UserDefaults.standard.set(NSStringFromRect(frame), forKey: "panelFrame")
        }
    }
}

// MARK: - String Extension for FourCharCode
extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf8 {
            result = result << 8 + FourCharCode(char)
        }
        return result
    }
}
