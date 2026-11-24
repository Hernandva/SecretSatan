import SwiftUI

/// Multi-line text input, e.g. a message. It grows with the text up to `lineLimit` lines and then scrolls.
/// `text` is the placeholder, so `.localized(_:)` localises it.
public struct DSTextView: View, DSLocalizableText {
    /// Lines shown while the text is short.
    static let minimumLines = 4

    public var text: String
    @Binding private var value: String
    private let lineLimit: Int

    public init(_ placeholder: String = "", value: Binding<String>, lineLimit: Int = 10) {
        self.text = placeholder
        self._value = value
        self.lineLimit = max(lineLimit, Self.minimumLines)
    }

    public var body: some View {
        TextField(text, text: $value, axis: .vertical)
            .lineLimit(Self.minimumLines...lineLimit)
            .textFieldStyle(.plain)
            .font(DSFont.body)
            .foregroundStyle(DSColor.textPrimary)
            .padding(.horizontal, DSSpacing.medium)
            .padding(.vertical, DSSpacing.space3)
            .frame(minHeight: DSSpacing.tapMin)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
    }
}

#Preview {
    VStack(spacing: DSSpacing.medium) {
        DSTextView("Message", value: .constant(""))
        DSTextView("Message", value: .constant("Bring something handmade.\nBudget: 30 €."))
    }
    .padding()
}
