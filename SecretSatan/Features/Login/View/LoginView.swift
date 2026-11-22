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

            DSButton(icon: .symbol("apple.logo")) {
                viewModel.continueWithApple()
            }
            .localized("login.continueWithApple")

            DSButton(style: .outline, icon: .glyph("G")) {
                viewModel.continueWithGoogle()
            }
            .localized("login.continueWithGoogle")
        }
        .padding(.horizontal, DSSpacing.medium)
        .padding(.bottom, DSSpacing.large)
        .background(DSColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
