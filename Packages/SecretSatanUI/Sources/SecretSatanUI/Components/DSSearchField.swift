import SwiftUI

/// Search input: a magnifying glass, the text field and a button that clears it once something is typed.
/// `text` is the placeholder, so `.localized(_:)` localises it.
public struct DSSearchField: View, DSLocalizableText {
    public var text: String
    @Binding private var query: String

    public init(_ placeholder: String = "", query: Binding<String>) {
        self.text = placeholder
        self._query = query
    }

    public var body: some View {
        HStack(spacing: DSSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DSColor.textSecondary)
                .accessibilityHidden(true)
            TextField(text, text: $query)
                .textFieldStyle(.plain)
                .font(DSFont.body)
                .foregroundStyle(DSColor.textPrimary)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DSColor.textSecondary)
                        .frame(minWidth: DSSpacing.tapMin, minHeight: DSSpacing.tapMin)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(forKey: "ds.search.clear", value: "Clear"))
            }
        }
        .padding(.leading, DSSpacing.medium)
        .padding(.trailing, query.isEmpty ? DSSpacing.medium : 0)
        .frame(minHeight: DSSpacing.tapMin)
        .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
    }
}

#Preview {
    VStack(spacing: DSSpacing.medium) {
        DSSearchField("Search", query: .constant(""))
        DSSearchField("Search", query: .constant("Lucía"))
    }
    .padding()
}
