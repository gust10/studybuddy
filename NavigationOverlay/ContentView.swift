import SwiftUI

// MARK: - Collapsed strip width

private let stripWidth: CGFloat    = 6   // visible edge strip when collapsed
private let expandedWidth: CGFloat = 220 // full panel width when expanded
private let verticalPadding: CGFloat = 14

struct ContentView: View {
    @State private var isExpanded = false
    @State private var selectedID: UUID? = NavItem.defaults.first?.id

    private let items = NavItem.defaults

    var body: some View {
        HStack(spacing: 0) {
            // ── Wall strip (always visible, anchored to left screen edge) ──
            wallStrip

            // ── Navigation panel ──
            navigationPanel
                .frame(width: isExpanded ? expandedWidth : 0)
                .clipped()

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded = hovering
            }
        }
    }

    // MARK: - Strip

    private var wallStrip: some View {
        VStack(spacing: 6) {
            ForEach(items) { item in
                Circle()
                    .fill(selectedID == item.id ? Color.accentColor : Color.primary.opacity(0.18))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: stripWidth)
        .frame(maxHeight: .infinity)
        .background(
            Color.primary.opacity(isExpanded ? 0 : 0.06)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        )
    }

    // MARK: - Panel

    private var navigationPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──
            header
                .padding(.top, verticalPadding)
                .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 10)
                .padding(.bottom, 6)

            // ── Nav items ──
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(items) { item in
                        NavItemView(
                            item: item,
                            isExpanded: isExpanded,
                            isSelected: selectedID == item.id
                        ) {
                            let wasSelected = selectedID == item.id
                            selectedID = wasSelected ? nil : item.id
                            // Toggle content panel off if same item tapped twice
                            let title: String? = wasSelected ? nil : item.title
                            NotificationCenter.default.post(
                                name: .navItemSelected,
                                object: title
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 0)

            // ── Quit button at bottom ──
            quitButton
                .padding(.bottom, verticalPadding)
        }
        .frame(maxHeight: .infinity)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 16, x: 6, y: 0)
        .padding(.vertical, verticalPadding)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                .padding(.leading, 12)

            if isExpanded {
                VStack(alignment: .leading, spacing: 1) {
                    Text("StudyBuddy")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Navigation")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Quit button

    private var quitButton: some View {
        NavItemView(
            item: NavItem(title: "Quit", icon: "xmark.circle"),
            isExpanded: isExpanded,
            isSelected: false
        ) {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - Background

    private var panelBackground: some View {
        ZStack {
            VisualEffectView()

            // Thin right-edge separator
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 0.5)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 260, height: 700)
}
