import SecretSatanUI
import SwiftUI

/// "Eventos": the user's events and the button to add a new one.
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
                    .frame(maxWidth: .infinity)
            case .loaded:
                content
            case .failed:
                DSText(style: .footnote, color: DSColor.destructive).localized("home.error")
            }
        }
        .dsBottomBar {
            if viewModel.state == .loaded, viewModel.viewData.user != nil {
                // Opens the screen to create an event once that feature exists.
                DSButton(icon: .symbol("plus")) {}
                    .localized("home.addEvent")
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewData.user == nil {
            DSText(style: .body, color: DSColor.textSecondary).localized("home.noSession")
        } else if viewModel.viewData.events.isEmpty {
            DSText(style: .body, color: DSColor.textSecondary).localized("home.empty")
        } else {
            DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                ForEach(viewModel.viewData.events) { event in
                    DSListRow(
                        event.name,
                        subtitle: String(localized: "home.event.participants \(event.participantCount)"),
                        icon: "gift",
                        showsChevron: true
                    )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeCoordinator().start()
    }
}
