import Foundation

struct NavItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String      // SF Symbol name
    var badge: Int? = nil // optional notification badge
}

// MARK: - Default items

extension NavItem {
    static let defaults: [NavItem] = [
        NavItem(title: "Home",      icon: "house.fill"),
        NavItem(title: "Search",    icon: "magnifyingglass"),
        NavItem(title: "Notes",     icon: "note.text"),
        NavItem(title: "Calendar",  icon: "calendar"),
        NavItem(title: "Reminders", icon: "bell.fill", badge: 3),
        NavItem(title: "Settings",  icon: "gearshape.fill"),
    ]
}
