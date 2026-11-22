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
                // Compose the screen with SecretSatanUI components fed by `viewModel.viewData`.
                EmptyView()
            case .failed(let message):
                DSText(message, style: .footnote, color: DSColor.destructive)
            }
        }
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        HomeCoordinator().start()
    }
}
