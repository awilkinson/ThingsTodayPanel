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
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for a cleaner experience
        NSApp.setActivationPolicy(.accessory)

        // Check and request Accessibility permissions for global hotkey
        checkAccessibilityPermissions()

        // Create menu bar item with star icon
        setupMenuBar()

        // Check if first launch - show onboarding
        if !UserDefaults.standard.hasCompletedOnboarding {
            showOnboarding()
        } else {
            // Create and show the floating panel
            showFloatingPanel()
        }

        // Set up global hotkey (Command + Control + Shift + T)
        setupGlobalHotkey()
    }

    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️ Accessibility permissions not granted - global hotkey will not work")

            // Show alert to open System Settings manually
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "Things Today Panel needs Accessibility permissions to register the global hotkey (⌘⌃⇧T).\n\nClick 'Open System Settings' to grant permission, then restart the app."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Skip")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // Open System Settings to Accessibility pane
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        } else {
            print("✅ Accessibility permissions granted")
        }
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
            button.toolTip = "Things Today Panel (⌘⌃⇧T)"
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
        // Create a binding that closes the window when set to false
        let binding = Binding<Bool>(
            get: { true },
            set: { [weak self] newValue in
                if !newValue {
                    self?.onboardingWindow?.close()
                    self?.onboardingWindow = nil
                    self?.showFloatingPanel()
                }
            }
        )

        let onboardingView = OnboardingView(isPresented: binding)

        let hostingController = NSHostingController(rootView: onboardingView)
        onboardingWindow = NSWindow(contentViewController: hostingController)

        onboardingWindow?.styleMask = [.titled, .closable]
        onboardingWindow?.title = "Welcome"
        onboardingWindow?.center()
        onboardingWindow?.makeKeyAndOrderFront(nil)
        onboardingWindow?.level = .floating

        // When onboarding closes manually, show main panel
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: onboardingWindow,
            queue: .main
        ) { [weak self] _ in
            if self?.floatingPanel == nil {
                self?.showFloatingPanel()
            }
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
        print("🔵 togglePanel called")
        if let panel = floatingPanel {
            print("🔵 panel exists, isVisible: \(panel.isVisible)")
            if panel.isVisible {
                print("🔵 hiding panel")
                panel.orderOut(nil)
            } else {
                print("🔵 showing panel")
                showFloatingPanel()
            }
        } else {
            print("🔵 panel doesn't exist, creating new one")
            showFloatingPanel()
        }
        print("🔵 togglePanel completed")
    }

    func showFloatingPanel() {
        print("🟢 showFloatingPanel called")
        if floatingPanel == nil {
            print("🟢 Creating new FloatingPanelWindow")
            floatingPanel = FloatingPanelWindow()
        }

        print("🟢 Making panel key and ordering front")
        floatingPanel?.makeKeyAndOrderFront(nil)
        floatingPanel?.center()

        // Restore saved position if available
        if let savedFrame = UserDefaults.standard.string(forKey: "panelFrame") {
            if let frame = NSRectFromString(savedFrame) as NSRect? {
                floatingPanel?.setFrame(frame, display: true)
            }
        }
        print("🟢 showFloatingPanel completed, panel isVisible: \(floatingPanel?.isVisible ?? false)")
    }

    func setupGlobalHotkey() {
        // Register Command+Control+Shift+T hotkey using Carbon (works globally)
        let modifiers: UInt32 = UInt32(cmdKey | controlKey | shiftKey)
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
                print("🟢 Hotkey pressed!")
                // Toggle panel when hotkey is pressed
                guard let userData = userData else {
                    print("🔴 No userData")
                    return noErr
                }

                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                print("🟢 Got appDelegate, calling togglePanel")
                DispatchQueue.main.async {
                    appDelegate.togglePanel()
                }
                return noErr
            },
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &hotkeyEventHandler
        )

        // Register hotkey (stored as instance variable to prevent deallocation)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Never quit when windows are closed - we're a menu bar app
        print("🟡 applicationShouldTerminateAfterLastWindowClosed called - returning false")
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Only allow termination when explicitly quit from menu
        // This prevents the app from quitting when windows close
        print("🟡 applicationShouldTerminate called - allowing termination")

        // Save window position before quitting
        if let frame = floatingPanel?.frame {
            UserDefaults.standard.set(NSStringFromRect(frame), forKey: "panelFrame")
        }

        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("🔴 applicationWillTerminate called - app is quitting!")
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
