import SecretSatanUI
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: HomeDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            DSText(style: .largeTitle).localized("home.title")

            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded:
                content
            case .failed:
                DSText(style: .footnote, color: DSColor.destructive).localized("home.error")
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if let user = viewModel.viewData.user {
            DSCard {
                if let name = user.name {
                    DSText(name, style: .headline)
                } else {
                    DSText(style: .headline).localized("home.user.unnamed")
                }
                if let email = user.email {
                    DSText(email, style: .body, color: DSColor.textSecondary)
                }
            }
        } else {
            DSText(style: .body, color: DSColor.textSecondary).localized("home.noSession")
        }
    }
}

#Preview {
    NavigationStack {
        HomeCoordinator().start()
    }
}
