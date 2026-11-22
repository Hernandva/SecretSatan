# SecretSatanUI — configuration

The `SecretSatanUI` package holds the design system of `SecretSatan`, generated from a Claude Design design system, and the components built on it.
Feature views only add these components. They never set colors, fonts, spacing or corner radii themselves.

## Source of truth

- `tokens.json` (this folder) is the tokens export of the Claude Design design system. In Claude Design it is `project/tokens.json`.
- `Sources/SecretSatanUI/Tokens/*.swift` and `Sources/SecretSatanUI/Resources/Colors.xcassets` are **generated** from it. Do not edit them by hand.
- To update the design system, replace `tokens.json` and run:

```
python3 scripts/codegen/design_tokens.py Packages/SecretSatanUI/tokens.json Packages/SecretSatanUI
```

## Tokens

| Swift type | Contents |
|---|---|
| `DSPalette` | Every color token, with light and dark values, from the asset catalog. |
| `DSColor` | Semantic roles used by the components: `background`, `surface`, `textPrimary`, `textSecondary`, `accent`, `onAccent`, `fillSecondary`, `destructive`, `onDestructive`, `separator`. |
| `DSTypeScale` / `DSFont` | Every type style / semantic fonts: `largeTitle`, `title`, `headline`, `body`, `bodyStrong`, `footnote`, `caption`. |
| `DSSpacing` | Every spacing token, plus `xSmall`, `small`, `medium`, `large`, `xLarge` and `tapMin`. |
| `DSRadius` | Every radius token, plus `small`, `control` and `card`. |

Custom fonts named in the tokens must be added to the app bundle (`.ttf`/`.otf`) and registered under `UIAppFonts` (iOS) or `ATSApplicationFontsPath` (macOS). Until then, SwiftUI falls back to the system font.

## Components

| Component | Use |
|---|---|
| `DSScreen { … }` | Root container of every screen: scroll view, background and margins. |
| `DSText(_:style:color:)` | Any text. |
| `DSButton(_:style:icon:action:)` | Actions: 50 pt pill. Styles: `.primary`, `.secondary`, `.outline`, `.destructive`. Dimmed while `.disabled(true)`. Optional leading `icon`: `.symbol("apple.logo")` (SF Symbol) or `.glyph("G")`. |
| `DSLinkButton(_:value:style:icon:)` | `DSButton` that pushes a screen with `NavigationLink(value:)`. Same pill, styles and icons. Use it for buttons that open a route. |
| `DSTextField(_:value:)` | Text input. The first parameter is the placeholder. |
| `DSDatePicker(_:date:placeholder:)` | Date input with a label. The date is optional: while it is `nil` it shows `placeholder` (already localised) as a button; tapping it picks today and shows the compact picker. |
| `DSToggle(_:isOn:)` | Switch with a label. |
| `DSSectionHeader(_:)` | Header above a group of rows. |
| `DSListRow(_:subtitle:icon:initials:showsChevron:)` | Row in a list. With `icon` (SF Symbol) it shows a 40 pt tile of the primary color and the headline / subheadline type. With `initials` it shows them on a 40 pt round avatar (`fillSecondary`), as in the participant list. |
| `DSListGroup(separatorInset:) { … }` | Rows on a rounded surface (`radiusGroup`) with separators between them. Use `DSListRow.iconSeparatorInset` for rows with an icon. |
| `.dsBottomBar { … }` | Pins the screen's main button to the bottom, above the safe area, with the screen margins and background. |
| `.dsSwipeToDelete(_:action:)` | On a row of a `DSListGroup`: dragging it left reveals a destructive button that runs `action`; also a VoiceOver action. |
| `DSCard { … }` | Groups content on a surface. |
| `DSAppleSignInButton(type:action:)` | Apple's own Sign in with Apple button (iOS), pill shaped and as tall as `DSButton`. Apple localises the text; black in light mode, white in dark mode. |
| `DSAppMark(systemName:)` | App mark: SF Symbol on an 88 pt rounded square of the primary color (login header). |

New components go in `Sources/SecretSatanUI/Components/`, use only tokens, are `public` and include a `#Preview`. A component that shows a single text conforms to `DSLocalizableText`; components with several texts take them already localised.

## Localisation: `.localized(_:)`

Every component that shows text conforms to `DSLocalizableText` and gets a public `localized` extension. It receives a key, localises it and returns the component with the localised text:

```swift
DSText(style: .largeTitle).localized("profile.title")
DSButton { viewModel.save() }.localized("profile.save")
DSTextField(value: $email).localized("login.email.placeholder")
```

For a plain SwiftUI `Text`, use `Text(forKey:value:)`. It looks the key up with `Bundle.localizedString(forKey:value:table:)`, and `value` is the text shown when the key is not in the catalog (without it, the key is shown):

```swift
Text(forKey: "profile.title", value: "Profile")
```

Keys are looked up in the app's `Localizable.xcstrings` (`Bundle.main`). Pass `table:` and `bundle:` to use another catalog. Both accept them. Because the key is passed as a value, Xcode does not extract it automatically, so add every new key to the String Catalog.
