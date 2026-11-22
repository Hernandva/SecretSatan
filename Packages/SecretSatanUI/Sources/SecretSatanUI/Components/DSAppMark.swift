import SwiftUI

/// App mark: an SF Symbol on a rounded square of the primary color, as on the login screen.
public struct DSAppMark: View {
    /// Side of the square.
    static let side: CGFloat = 88
    /// Corner radius of the square, a quarter of its side like an app icon.
    static let cornerRadius: CGFloat = side / 4
    /// Point size of the symbol inside the square.
    static let symbolSize: CGFloat = 44

    private let systemName: String

    public init(systemName: String) {
        self.systemName = systemName
    }

    public var body: some View {
        Image(systemName: systemName)
            .font(.system(size: Self.symbolSize, weight: .light))
            .foregroundStyle(DSColor.onAccent)
            .frame(width: Self.side, height: Self.side)
            .background(
                DSColor.accent,
                in: RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    DSAppMark(systemName: "gift")
        .padding()
}
