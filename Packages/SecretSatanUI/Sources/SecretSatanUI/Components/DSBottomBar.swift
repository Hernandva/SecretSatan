import SwiftUI

public extension View {
    /// Pins `content` (usually the screen's main button) to the bottom of the screen, above the safe area,
    /// with the screen margins and background. The scrolling content of `DSScreen` stops above it.
    func dsBottomBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: DSSpacing.small) {
                content()
            }
            .padding(.horizontal, DSSpacing.medium)
            .padding(.top, DSSpacing.small)
            .padding(.bottom, DSSpacing.small)
            .background(DSColor.background)
        }
    }
}

#Preview {
    DSScreen {
        DSText("Screen", style: .largeTitle)
    }
    .dsBottomBar {
        DSButton("Add", icon: .symbol("plus")) {}
    }
}
