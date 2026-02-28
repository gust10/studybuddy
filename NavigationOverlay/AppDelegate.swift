import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayPanel: NSPanel?
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory: no Dock icon, no menu bar app, just an overlay
        NSApp.setActivationPolicy(.accessory)
        setupOverlayPanel()
    }

    // MARK: - Panel Setup

    private func setupOverlayPanel() {
        guard let screen = NSScreen.main else { return }

        let frame = panelFrame(for: screen)

        let panel = WallPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let rootView = ContentView()
        panel.contentView = NSHostingView(rootView: rootView)

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false          // SwiftUI handles its own shadow
        panel.isMovable = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]

        panel.orderFrontRegardless()
        self.overlayPanel = panel

        // Re-anchor when display configuration changes
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.repositionPanel()
        }
    }

    // MARK: - Positioning

    private func panelFrame(for screen: NSScreen) -> NSRect {
        let vis = screen.visibleFrame
        // Full left-edge column; width gives the expanded SwiftUI view room to breathe
        return NSRect(x: vis.minX, y: vis.minY, width: 260, height: vis.height)
    }

    @objc private func repositionPanel() {
        guard let screen = NSScreen.main, let panel = overlayPanel else { return }
        let newFrame = panelFrame(for: screen)
        panel.setFrame(newFrame, display: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - WallPanel

/// A borderless NSPanel subclass that accepts key/mouse events while staying non-activating.
final class WallPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func performKeyEquivalent(with event: NSEvent) -> Bool { false }
}
