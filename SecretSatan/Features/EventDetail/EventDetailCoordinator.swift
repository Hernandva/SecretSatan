import SwiftUI

/// Entry point of the EventDetail feature.
/// Builds the view through `EventDetailDependencies` and resolves the routes to the features opened from it.
@MainActor
final class EventDetailCoordinator: Coordinator {
    /// One case per feature that can be opened from EventDetail.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: EventDetailDependencies

    init(dependencies: EventDetailDependencies) {
        self.dependencies = dependencies
    }

    func start() -> some View {
        EventDetailView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        // @codegen:destinations
        }
    }
}
