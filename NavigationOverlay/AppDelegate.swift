import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var navPanel:     NSPanel?
    private var convPanel:    NSPanel?
    private var contentPanel: NSPanel?
    private var observers:    [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        seedCredentials()
        setupNavPanel()
        setupConvPanel()
        setupContentPanel()
        observeNavSelection()
        observeScreenChanges()
    }

    // MARK: - Seed credentials

    private func seedCredentials() {
        let ud = UserDefaults.standard
        ud.set("sk_e14afd6292b7b343f0e780eb0d29dc4196216c8701d52fdc", forKey: "el_api_key")
        ud.set("agent_7101kjhrtk5mebn9ywxnx5wbc1p0",                 forKey: "el_agent_id")
        // Canvas URL default (HKUST) — token must be entered by user
        if ud.string(forKey: "canvas_url") == nil {
            ud.set("https://canvas.ust.hk", forKey: "canvas_url")
        }
    }

    // MARK: - Nav panel (left wall strip)

    private func setupNavPanel() {
        guard let screen = NSScreen.main else { return }
        let panel = makePanel(frame: navFrame(for: screen))
        panel.contentView = NSHostingView(rootView: ContentView())
        panel.orderFrontRegardless()
        navPanel = panel
    }

    // MARK: - Conversation panel (center, above dock)

    private func setupConvPanel() {
        guard let screen = NSScreen.main else { return }
        let panel = makePanel(frame: convFrame(for: screen))
        panel.contentView = NSHostingView(rootView: ConversationView())
        panel.orderFrontRegardless()
        convPanel = panel
    }

    // MARK: - Content panel (beside nav, shows section views)

    private func setupContentPanel() {
        guard let screen = NSScreen.main else { return }
        let panel = makePanel(frame: contentFrame(for: screen))
        panel.contentView = NSHostingView(rootView: EmptyView())
        // Hidden until a nav item is selected
        contentPanel = panel
    }

    private func showContentPanel(for title: String?) {
        guard let panel = contentPanel, let screen = NSScreen.main else { return }

        guard let title else {
            panel.orderOut(nil)
            return
        }

        let view: AnyView = switch title {
        case "Todo":
            AnyView(
                TodoView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 14)
                    .padding(.trailing, 8)
            )
        default:
            AnyView(placeholderView(for: title))
        }

        panel.contentView = NSHostingView(rootView: view)
        panel.setFrame(contentFrame(for: screen), display: false)
        panel.orderFrontRegardless()
    }

    private func placeholderView(for title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2.bold())
            Text("Coming soon")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 18, x: 6)
        .padding(.vertical, 14)
        .padding(.trailing, 8)
    }

    // MARK: - Observation

    private func observeNavSelection() {
        let obs = NotificationCenter.default.addObserver(
            forName: .navItemSelected,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.showContentPanel(for: note.object as? String)
        }
        observers.append(obs)
    }

    private func observeScreenChanges() {
        let obs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.repositionAll()
        }
        observers.append(obs)
    }

    // MARK: - Frames

    private func navFrame(for screen: NSScreen) -> NSRect {
        let vis = screen.visibleFrame
        return NSRect(x: vis.minX, y: vis.minY, width: 260, height: vis.height)
    }

    private func convFrame(for screen: NSScreen) -> NSRect {
        let vis   = screen.visibleFrame
        let w: CGFloat = 380
        let h: CGFloat = 180
        return NSRect(x: vis.midX - w / 2, y: vis.minY + 12, width: w, height: h)
    }

    private func contentFrame(for screen: NSScreen) -> NSRect {
        let vis = screen.visibleFrame
        let x   = vis.minX + 268       // right of nav panel (260) + 8px gap
        let w   = min(400, vis.width - 280)
        return NSRect(x: x, y: vis.minY, width: w, height: vis.height)
    }

    private func repositionAll() {
        guard let screen = NSScreen.main else { return }
        navPanel?.setFrame(navFrame(for: screen), display: true)
        convPanel?.setFrame(convFrame(for: screen), display: true)
        if contentPanel?.isVisible == true {
            contentPanel?.setFrame(contentFrame(for: screen), display: true)
        }
    }

    // MARK: - Shared factory

    private func makePanel(frame: NSRect) -> NSPanel {
        let panel = WallPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level           = .floating
        panel.isOpaque        = false
        panel.backgroundColor = .clear
        panel.hasShadow       = false
        panel.isMovable       = false
        panel.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary
        ]
        return panel
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - WallPanel

final class WallPanel: NSPanel {
    override var canBecomeKey:  Bool { true }
    override var canBecomeMain: Bool { false }
    override func performKeyEquivalent(with event: NSEvent) -> Bool { false }
}
