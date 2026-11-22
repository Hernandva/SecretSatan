import SwiftUI
#if os(iOS)
import UIKit
#endif

public extension View {
    /// Dragging the row to the left reveals a destructive button with `label`; tapping it runs `action`.
    /// Tapping the row or dragging it back closes the button. VoiceOver gets the same action from the rotor.
    ///
    /// Made for rows of a `DSListGroup` inside a `DSScreen`, where `List.swipeActions` is not available.
    /// Vertical drags that start on the row still scroll the screen, and a swipe never triggers the row's own tap
    /// (e.g. its `NavigationLink`).
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
    /// How long the row ignores taps after a swipe ends, so lifting the finger doesn't open it.
    static let tapBlockAfterSwipe: Duration = .milliseconds(300)
    /// Share of the release velocity added to the translation to predict where the swipe ends.
    static let velocityProjection: CGFloat = 0.2

    let label: String
    let action: @MainActor () -> Void

    @State private var offset: CGFloat = 0
    @State private var isOpen = false
    /// `true` while a swipe is in progress and shortly after, so the row's own tap (e.g. a `NavigationLink`)
    /// doesn't fire when the finger is lifted.
    @State private var blocksTap = false

    func body(content: Content) -> some View {
        content
            .disabled(blocksTap)
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
            .gesture(swipe)
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

    #if os(iOS)
    /// A UIKit pan that only begins when the finger moves more sideways than up or down, so vertical drags stay
    /// with the scroll view. A SwiftUI `DragGesture` would take every drag that starts on the row.
    private var swipe: DSHorizontalPan {
        DSHorizontalPan(
            onChanged: { translation in swipeChanged(translation) },
            onEnded: { translation, velocity in
                swipeEnded(predicted: translation + velocity * Self.velocityProjection)
            }
        )
    }
    #else
    private var swipe: some Gesture {
        DragGesture(minimumDistance: DSSpacing.large)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                swipeChanged(value.translation.width)
            }
            .onEnded { value in swipeEnded(predicted: value.predictedEndTranslation.width) }
    }
    #endif

    private var restingOffset: CGFloat {
        isOpen ? -Self.actionWidth : 0
    }
}

private extension DSSwipeToDelete {
    func swipeChanged(_ translation: CGFloat) {
        blocksTap = true
        let proposed = restingOffset + translation
        offset = min(0, max(proposed, -(Self.actionWidth + Self.overscroll)))
    }

    func swipeEnded(predicted translation: CGFloat) {
        setOpen(restingOffset + translation < -Self.actionWidth / 2)
        releaseTap()
    }

    /// Lets the row take taps again a moment after the swipe, once the finger's touch-up has been ignored.
    func releaseTap() {
        Task { @MainActor in
            try? await Task.sleep(for: Self.tapBlockAfterSwipe)
            blocksTap = false
        }
    }

    func setOpen(_ open: Bool) {
        withAnimation(.snappy) {
            isOpen = open
            offset = open ? -Self.actionWidth : 0
        }
    }
}

#if os(iOS)
/// Horizontal pan for `dsSwipeToDelete`. It reports the horizontal translation while the finger moves and, when it
/// lifts, the translation and the velocity. It never begins for a mostly vertical drag, which scrolls instead.
struct DSHorizontalPan: UIGestureRecognizerRepresentable {
    let onChanged: @MainActor (CGFloat) -> Void
    let onEnded: @MainActor (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed:
            onChanged(translation)
        case .ended, .cancelled:
            onEnded(translation, recognizer.velocity(in: recognizer.view).x)
        default:
            break
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Begins only when the finger moves more sideways than up or down.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
#endif

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
