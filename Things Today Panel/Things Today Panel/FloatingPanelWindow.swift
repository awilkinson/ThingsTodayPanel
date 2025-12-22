import AppKit
import SwiftUI

class FloatingPanelWindow: NSPanel {
    init() {
        // Create with a nice default size
        let contentRect = NSRect(x: 0, y: 0, width: 360, height: 520)

        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Prevent window from releasing when closed
        self.isReleasedWhenClosed = false

        // Set delegate to self to intercept close
        self.delegate = self

        // Panel behavior - stays on top, non-activating
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true

        // Beautiful translucent background
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        // Title bar styling
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden

        // Window behavior
        self.isMovableByWindowBackground = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true

        // Set minimum and maximum sizes
        self.minSize = NSSize(width: 200, height: 250)
        self.maxSize = NSSize(width: 600, height: 900)

        // Create visual effect view for translucency
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true

        // Create and set the SwiftUI content view
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear

        // Add hosting view to visual effect view
        visualEffectView.addSubview(hostingView)
        hostingView.frame = visualEffectView.bounds
        hostingView.autoresizingMask = [.width, .height]

        self.contentView = visualEffectView

        // Animate in with a subtle spring
        self.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    // Override to prevent window from closing app - just hide instead
    override func close() {
        // Clear any focused controls before hiding
        self.makeFirstResponder(nil)

        // Animate out
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: {
            // Hide instead of closing to prevent app from quitting
            self.orderOut(nil)
            self.alphaValue = 1 // Reset alpha for next show
        })
    }

    // Handle escape key to hide (not close)
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

// MARK: - Window Delegate
extension FloatingPanelWindow: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Never actually close - just hide instead
        close()
        return false
    }

    func windowDidMove(_ notification: Notification) {
        // Save position immediately when user moves the window
        // This ensures the window always reappears exactly where the user left it
        if let window = notification.object as? NSWindow {
            UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: "panelFrame")
        }
    }

    func windowDidResize(_ notification: Notification) {
        // Save size immediately when user resizes the window
        if let window = notification.object as? NSWindow {
            UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: "panelFrame")
        }
    }
}
