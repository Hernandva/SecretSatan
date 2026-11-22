import SecretSatanUI
import SwiftUI

/// "Eventos": the user's events and the button to add a new one.
struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var isPresentingNewEvent = false
    /// Kept to build the "Nuevo evento" sheet with the same dependencies.
    private let dependencies: HomeDependencies

    /// Receives only the container and resolves the view model from it.
    init(dependencies: HomeDependencies) {
        self.dependencies = dependencies
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
                DSButton(icon: .symbol("plus")) { isPresentingNewEvent = true }
                    .localized("home.addEvent")
            }
        }
        .sheet(isPresented: $isPresentingNewEvent) {
            Task { await viewModel.reloadEvents() }
        } content: {
            NewEventView(dependencies: dependencies)
        }
        .alert(
            Text(forKey: "home.deleteError", value: "Couldn't delete the event."),
            isPresented: $viewModel.deleteFailed
        ) {}
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
                    NavigationLink(value: HomeCoordinator.Route.eventDetail(event)) {
                        DSListRow(
                            event.name,
                            subtitle: subtitle(for: event),
                            icon: "gift",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    .dsSwipeToDelete(String(localized: "home.event.delete")) {
                        Task { await viewModel.deleteEvent(event) }
                    }
                }
            }
        }
    }

    /// "12 dic 2026 · 6 participantes", or only the participants when the event has no date.
    private func subtitle(for event: HomeViewData.Event) -> String {
        let participants = String(localized: "home.event.participants \(event.participantCount)")
        guard let date = event.date else { return participants }
        return "\(date.formatted(date: .abbreviated, time: .omitted)) · \(participants)"
    }
}

#Preview {
    NavigationStack {
        HomeCoordinator().start()
    }
}
