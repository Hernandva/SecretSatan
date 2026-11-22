import SwiftUI

/// Icon-only button with a 44 pt tap target, e.g. the pencil that edits a field. The icon uses the primary color.
/// `text` is the accessibility label, so `.localized(_:)` localises it.
///
///     DSIconButton(systemName: "pencil") { edit() }
///         .localized("eventDetail.editName")
public struct DSIconButton: View, DSLocalizableText {
    public var text: String
    private let systemName: String
    private let action: @MainActor () -> Void

    /// - Parameters:
    ///   - label: Accessibility label, e.g. "Edit name".
    ///   - systemName: SF Symbol of the icon.
    public init(_ label: String = "", systemName: String, action: @escaping @MainActor () -> Void) {
        self.text = label
        self.systemName = systemName
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(DSFont.headline)
                .foregroundStyle(DSColor.accent)
                .frame(width: DSSpacing.tapMin, height: DSSpacing.tapMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(text))
    }
}

#Preview {
    HStack {
        DSText("Family 2026", style: .largeTitle)
        Spacer(minLength: 0)
        DSIconButton("Edit name", systemName: "pencil") {}
    }
    .padding()
    .background(DSColor.background)
}
