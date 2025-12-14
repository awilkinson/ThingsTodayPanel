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

    // Override to prevent window from closing app
    override func close() {
        // Animate out
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: {
            super.close()
        })
    }

    // Handle escape key to close
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
