import SwiftUI

/// Entry point of the Home feature.
/// Builds the view through `HomeDependencies` and resolves the routes to the features opened from it.
@MainActor
final class HomeCoordinator: Coordinator {
    /// One case per feature that can be opened from Home.
    enum Route: Hashable {
        /// Detail of the event selected in the list.
        case eventDetail(HomeViewData.Event)
        // @codegen:routes
    }

    private let dependencies: HomeDependencies

    init(dependencies: HomeDependencies = HomeDependencies()) {
        self.dependencies = dependencies
    }

    func start() -> some View {
        HomeView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        case .eventDetail(let event):
            let detailEvent = EventDetailViewData.Event(
                id: event.id,
                name: event.name,
                date: event.date,
                message: event.message,
                participantCount: event.participantCount,
                isDrawn: event.isDrawn
            )
            let detailDependencies = EventDetailDependencies(event: detailEvent)
            return AnyView(EventDetailCoordinator(dependencies: detailDependencies).start())
        // @codegen:destinations
        }
    }
}
