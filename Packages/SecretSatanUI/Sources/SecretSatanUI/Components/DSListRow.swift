import SwiftUI

/// Row with a title, an optional subtitle, an optional leading icon and an optional chevron.
/// `.localized(_:)` localises the title.
///
/// With `icon`, the row shows the SF Symbol on a rounded tile of the primary color and uses the larger
/// headline / subheadline type, as in the event list.
/// With `initials` (and no `icon`), it shows them on a round avatar, as in the participant list.
/// Both leading views are 40 pt, so rows with either line up with `iconSeparatorInset`.
/// With `isSelected`, it shows a trailing check circle, filled with the primary color while selected, as in a list
/// where several rows can be picked.
public struct DSListRow: View, DSLocalizableText {
    /// Side of the icon tile.
    static let iconSide: CGFloat = 40
    /// Point size of the symbol inside the icon tile.
    static let iconSymbolSize: CGFloat = 20
    /// Separator inset that lines up with the title of rows that have an icon. Pass it to `DSListGroup`.
    public static let iconSeparatorInset: CGFloat = DSSpacing.medium + iconSide + DSSpacing.space3

    public var text: String
    private let subtitle: String?
    private let icon: String?
    private let initials: String?
    private let showsChevron: Bool
    private let isSelected: Bool?

    public init(
        _ text: String = "",
        subtitle: String? = nil,
        icon: String? = nil,
        initials: String? = nil,
        showsChevron: Bool = false,
        isSelected: Bool? = nil
    ) {
        self.text = text
        self.subtitle = subtitle
        self.icon = icon
        self.initials = initials
        self.showsChevron = showsChevron
        self.isSelected = isSelected
    }

    /// `true` when the row has a leading icon tile or avatar.
    private var hasLeadingView: Bool {
        icon != nil || initials != nil
    }

    public var body: some View {
        HStack(spacing: hasLeadingView ? DSSpacing.space3 : DSSpacing.small) {
            if let icon {
                iconTile(systemName: icon)
            } else if let initials {
                avatar(initials: initials)
            }
            VStack(alignment: .leading, spacing: icon == nil ? DSSpacing.xSmall : 0) {
                Text(text)
                    .font(icon == nil ? DSFont.body : DSFont.headline)
                    .foregroundStyle(DSColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(icon == nil ? DSFont.footnote : DSTypeScale.subheadline)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            Spacer(minLength: 0)
            if let isSelected {
                selectionMark(isSelected: isSelected)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, DSSpacing.medium)
        .padding(.vertical, verticalPadding)
        .frame(minHeight: DSSpacing.tapMin)
        .background(DSColor.surface)
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected == true ? .isSelected : [])
    }

    /// Icon rows are taller (68 pt), as in the event list; avatar rows are 56 pt, as in the participant list.
    private var verticalPadding: CGFloat {
        if icon != nil { return DSSpacing.space3 }
        return initials == nil ? 0 : DSSpacing.small
    }
}

private extension DSListRow {
    func selectionMark(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(DSFont.headline)
            .foregroundStyle(isSelected ? DSColor.accent : DSColor.textSecondary)
            .accessibilityHidden(true)
    }

    func avatar(initials: String) -> some View {
        Text(initials)
            .font(DSTypeScale.subheadline.weight(.semibold))
            .foregroundStyle(DSColor.textPrimary)
            .frame(width: Self.iconSide, height: Self.iconSide)
            .background(DSColor.fillSecondary, in: Circle())
            .accessibilityHidden(true)
    }

    func iconTile(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: Self.iconSymbolSize))
            .foregroundStyle(DSColor.onAccent)
            .frame(width: Self.iconSide, height: Self.iconSide)
            .background(
                DSColor.accent,
                in: RoundedRectangle(cornerRadius: DSRadius.radiusIcon, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 0) {
        DSListRow("Account", subtitle: "Signed in", showsChevron: true)
        DSListRow("Privacy", showsChevron: true)
        DSListRow("Family 2026", subtitle: "6 participants", icon: "gift", showsChevron: true)
        DSListRow("Lucía Martín", initials: "LM")
        DSListRow("Pablo Ruiz", subtitle: "600 000 001", initials: "PR", isSelected: true)
        DSListRow("Ana Gómez", subtitle: "600 000 002", initials: "AG", isSelected: false)
    }
}
