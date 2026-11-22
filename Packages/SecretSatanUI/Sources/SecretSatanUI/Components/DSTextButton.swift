import SwiftUI

/// Text-only button with an optional leading SF Symbol, in the primary color, with a 44 pt tap target.
/// For small actions beside a `DSSectionHeader`, e.g. "+ Añadir".
///
///     DSTextButton(icon: "plus") { add() }
///         .localized("participantDetail.add")
public struct DSTextButton: View, DSLocalizableText {
    public var text: String
    private let icon: String?
    private let action: @MainActor () -> Void

    /// - Parameters:
    ///   - text: Title of the button.
    ///   - icon: SF Symbol shown before the title, or `nil` for none.
    public init(_ text: String = "", icon: String? = nil, action: @escaping @MainActor () -> Void) {
        self.text = text
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.xSmall) {
                if let icon {
                    Image(systemName: icon)
                        .accessibilityHidden(true)
                }
                Text(text)
            }
            .font(DSFont.bodyStrong)
            .foregroundStyle(DSColor.accent)
            .frame(minHeight: DSSpacing.tapMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        DSSectionHeader("Exclusions")
        Spacer(minLength: 0)
        DSTextButton("Add", icon: "plus") {}
    }
    .padding()
    .background(DSColor.background)
}
