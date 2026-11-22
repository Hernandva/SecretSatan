import SwiftUI

/// Date input with a label, on the surface of a text field. `.localized(_:)` localises the label.
///
/// The date is optional: while it is `nil` the row shows `placeholder` as a button, and tapping it sets today's date
/// and shows the system's compact date picker. Use it for dates the user must choose on purpose.
public struct DSDatePicker: View, DSLocalizableText {
    public var text: String
    @Binding private var date: Date?
    private let placeholder: String

    /// - Parameters:
    ///   - label: Name of the field, e.g. "Date".
    ///   - date: The chosen date, `nil` until the user picks one.
    ///   - placeholder: Already localised text of the button shown while `date` is `nil`, e.g. "Choose".
    public init(_ label: String = "", date: Binding<Date?>, placeholder: String) {
        self.text = label
        self._date = date
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack(spacing: DSSpacing.small) {
            if let chosen = date {
                DatePicker(
                    selection: Binding(get: { chosen }, set: { date = $0 }),
                    displayedComponents: .date
                ) {
                    label
                }
                .tint(DSColor.accent)
            } else {
                label
                Spacer(minLength: 0)
                Button(placeholder) { date = Date() }
                    .font(DSFont.body)
                    .foregroundStyle(DSColor.accent)
            }
        }
        .padding(.horizontal, DSSpacing.medium)
        .frame(minHeight: DSSpacing.tapMin)
        .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.control, style: .continuous))
    }

    private var label: some View {
        Text(text)
            .font(DSFont.body)
            .foregroundStyle(DSColor.textPrimary)
    }
}

#Preview {
    @Previewable @State var empty: Date?
    @Previewable @State var chosen: Date? = Date()
    VStack {
        DSDatePicker("Date", date: $empty, placeholder: "Choose")
        DSDatePicker("Date", date: $chosen, placeholder: "Choose")
    }
    .padding()
    .background(DSColor.background)
}
