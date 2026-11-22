#if canImport(UIKit)
import AuthenticationServices
import SwiftUI

/// Apple's own "Sign in with Apple" button (`ASAuthorizationAppleIDButton`), sized like `DSButton`.
/// Apple localises its text and draws its logo. It is black in light mode and white in dark mode, like the primary
/// button. Tapping it only runs `action`; the caller starts the sign-in.
public struct DSAppleSignInButton: View {
    private let type: ASAuthorizationAppleIDButton.ButtonType
    private let action: @MainActor () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        type: ASAuthorizationAppleIDButton.ButtonType = .continue,
        action: @escaping @MainActor () -> Void
    ) {
        self.type = type
        self.action = action
    }

    public var body: some View {
        AppleIDButton(type: type, style: colorScheme == .dark ? .white : .black, action: action)
            // The button style is fixed when it is created, so a new one is built when the appearance changes.
            .id(colorScheme)
            .frame(maxWidth: .infinity)
            .frame(height: DSButton.height)
    }
}

private struct AppleIDButton: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let action: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: style)
        button.cornerRadius = DSButton.height / 2
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        context.coordinator.action = action
    }

    @MainActor
    final class Coordinator: NSObject {
        var action: @MainActor () -> Void

        init(action: @escaping @MainActor () -> Void) {
            self.action = action
        }

        @objc func didTap() {
            action()
        }
    }
}

#Preview {
    VStack {
        DSAppleSignInButton {}
        DSAppleSignInButton(type: .signIn) {}
            .environment(\.colorScheme, .dark)
    }
    .padding()
}
#endif
