import SwiftUI
import AppKit

@main
struct NavigationOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty settings scene — the real UI lives in the NSPanel
        Settings {
            EmptyView()
        }
    }
}
