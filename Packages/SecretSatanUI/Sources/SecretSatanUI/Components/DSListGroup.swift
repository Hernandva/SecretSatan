import SwiftUI

/// Groups rows on a rounded surface and draws a separator between each pair of rows.
///
///     DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
///         ForEach(events) { event in DSListRow(event.name, icon: "gift") }
///     }
public struct DSListGroup<Content: View>: View {
    private let separatorInset: CGFloat
    private let content: Content

    /// - Parameter separatorInset: Leading inset of the separators. Use `DSListRow.iconSeparatorInset`
    ///   for rows with an icon.
    public init(separatorInset: CGFloat = DSSpacing.medium, @ViewBuilder content: () -> Content) {
        self.separatorInset = separatorInset
        self.content = content()
    }

    public var body: some View {
        Group(subviews: content) { rows in
            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    if index > 0 {
                        DSColor.separator
                            .frame(height: 1)
                            .padding(.leading, separatorInset)
                    }
                    rows[index]
                }
            }
        }
        .background(DSColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: DSRadius.radiusGroup, style: .continuous))
    }
}

#Preview {
    DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
        DSListRow("Family 2026", subtitle: "6 participants", icon: "gift", showsChevron: true)
        DSListRow("Friends 2027", subtitle: "8 participants", icon: "gift", showsChevron: true)
    }
    .padding()
    .background(DSColor.background)
}
