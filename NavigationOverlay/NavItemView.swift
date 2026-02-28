import SwiftUI

struct NavItemView: View {
    let item: NavItem
    let isExpanded: Bool
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                // Icon + optional badge overlay
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 26, height: 26)
                        .foregroundStyle(isSelected ? .white : .primary.opacity(0.75))

                    if let badge = item.badge, badge > 0 {
                        Text(badge < 100 ? "\(badge)" : "99+")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red, in: Capsule())
                            .offset(x: 8, y: -6)
                    }
                }

                if isExpanded {
                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .leading)))

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.accentColor
                            : isHovered
                                ? Color.primary.opacity(0.07)
                                : Color.clear
                    )
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isExpanded)
    }
}
