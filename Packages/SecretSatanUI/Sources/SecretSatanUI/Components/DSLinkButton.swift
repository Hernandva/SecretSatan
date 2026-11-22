import SwiftUI

/// `DSButton` that pushes a screen: a `NavigationLink(value:)` with the same pill, styles and icon.
/// The enclosing `NavigationStack` resolves `value` through its `navigationDestination(for:)`.
public struct DSLinkButton<Value: Hashable>: View, DSLocalizableText {
    public var text: String
    private let value: Value
    private let style: DSButton.Style
    private let icon: DSButton.Icon?

    public init(
        _ text: String = "",
        value: Value,
        style: DSButton.Style = .primary,
        icon: DSButton.Icon? = nil
    ) {
        self.text = text
        self.value = value
        self.style = style
        self.icon = icon
    }

    public var body: some View {
        NavigationLink(value: value) {
            DSButtonLabel(text: text, icon: icon)
        }
        .buttonStyle(DSButtonStyle(style: style))
    }
}

#Preview {
    NavigationStack {
        VStack {
            DSLinkButton("Enter", value: 1)
            DSLinkButton("Details", value: 2, style: .outline, icon: .symbol("chevron.right"))
        }
        .padding()
        .navigationDestination(for: Int.self) { number in
            Text(verbatim: "Screen \(number)")
        }
    }
}
