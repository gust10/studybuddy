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
        NavItem(title: "Todo",           icon: "checklist"),
        NavItem(title: "Pomodoro",       icon: "timer"),
        NavItem(title: "Active Recall",  icon: "brain.head.profile"),
        NavItem(title: "Flash Card",     icon: "rectangle.on.rectangle"),
        NavItem(title: "Exam Simulator", icon: "doc.text.magnifyingglass"),
    ]
}
