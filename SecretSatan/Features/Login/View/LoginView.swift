import SecretSatanUI
import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: LoginDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        VStack(spacing: DSSpacing.space3) {
            header
                .frame(maxHeight: .infinity)

            if case .failed = viewModel.state {
                DSText(style: .footnote, color: DSColor.destructive).localized("login.error")
                    .multilineTextAlignment(.center)
            }

            actions
        }
        .disabled(viewModel.state == .loading)
        .padding(.horizontal, DSSpacing.medium)
        .padding(.bottom, DSSpacing.large)
        .background(DSColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.checkSession() }
    }

    /// "Enter" when there is a valid session, the sign-in buttons otherwise.
    @ViewBuilder
    private var actions: some View {
        if viewModel.state == .checkingSession {
            ProgressView()
                .frame(minHeight: DSSpacing.tapMin)
        } else if viewModel.viewData.hasSession {
            DSLinkButton(value: LoginCoordinator.Route.home)
                .localized("login.enter")
        } else {
            DSAppleSignInButton(type: .continue) {
                Task { await viewModel.continueWithApple() }
            }

            DSButton(style: .outline, icon: .glyph("G")) {
                Task { await viewModel.continueWithGoogle() }
            }
            .localized("login.continueWithGoogle")
        }
    }

    private var header: some View {
        VStack(spacing: DSSpacing.large) {
            DSAppMark(systemName: "gift")

            VStack(spacing: DSSpacing.small) {
                DSText(style: .largeTitle).localized("login.title")
                DSText(style: .body, color: DSColor.textSecondary).localized("login.subtitle")
            }
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    NavigationStack {
        LoginCoordinator().start()
    }
}
