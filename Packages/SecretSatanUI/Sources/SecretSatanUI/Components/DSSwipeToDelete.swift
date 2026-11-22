import SwiftUI

public extension View {
    /// Dragging the row to the left reveals a destructive button with `label`; tapping it runs `action`.
    /// Tapping the row or dragging it back closes the button. VoiceOver gets the same action from the rotor.
    ///
    /// Made for rows of a `DSListGroup` inside a `DSScreen`, where `List.swipeActions` is not available.
    ///
    ///     DSListRow(event.name, icon: "gift")
    ///         .dsSwipeToDelete(String(localized: "home.event.delete")) { delete(event) }
    func dsSwipeToDelete(_ label: String, action: @escaping @MainActor () -> Void) -> some View {
        modifier(DSSwipeToDelete(label: label, action: action))
    }
}

struct DSSwipeToDelete: ViewModifier {
    /// Width of the revealed button.
    static let actionWidth: CGFloat = 88
    /// How far past the button the row can be dragged, with resistance.
    static let overscroll: CGFloat = 32
    /// Horizontal distance before the drag starts, so vertical scrolling keeps working.
    static let minimumDragDistance: CGFloat = 20

    let label: String
    let action: @MainActor () -> Void

    @State private var offset: CGFloat = 0
    @State private var isOpen = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isOpen {
                    // Catches taps on the open row so they close it instead of opening the row.
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { setOpen(false) }
                }
            }
            .offset(x: offset)
            .background(alignment: .trailing) {
                if offset < 0 {
                    deleteButton
                }
            }
            .clipped()
            .simultaneousGesture(drag)
            .accessibilityAction(named: Text(label)) { action() }
    }

    private var deleteButton: some View {
        Button {
            setOpen(false)
            action()
        } label: {
            VStack(spacing: DSSpacing.xSmall) {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
                Text(label)
                    .font(DSFont.footnote)
            }
            .foregroundStyle(DSColor.onDestructive)
            .frame(width: max(Self.actionWidth, -offset))
            .frame(maxHeight: .infinity)
            .background(DSColor.destructive)
        }
        .buttonStyle(.plain)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: Self.minimumDragDistance)
            .onChanged { value in
                // Leave vertical drags to the scroll view.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                let proposed = restingOffset + value.translation.width
                offset = min(0, max(proposed, -(Self.actionWidth + Self.overscroll)))
            }
            .onEnded { value in
                let predicted = restingOffset + value.predictedEndTranslation.width
                setOpen(predicted < -Self.actionWidth / 2)
            }
    }

    private var restingOffset: CGFloat {
        isOpen ? -Self.actionWidth : 0
    }

    private func setOpen(_ open: Bool) {
        withAnimation(.snappy) {
            isOpen = open
            offset = open ? -Self.actionWidth : 0
        }
    }
}

#Preview {
    DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
        DSListRow("Family 2026", subtitle: "6 participants", icon: "gift", showsChevron: true)
            .dsSwipeToDelete("Delete") {}
        DSListRow("Friends 2027", subtitle: "8 participants", icon: "gift", showsChevron: true)
            .dsSwipeToDelete("Delete") {}
    }
    .padding()
    .background(DSColor.background)
}
