import SwiftUI

/// Entry point of the ParticipantDetail feature.
/// Builds the view through `ParticipantDetailDependencies` and resolves the routes to the features opened from it.
@MainActor
final class ParticipantDetailCoordinator: Coordinator {
    /// One case per feature that can be opened from ParticipantDetail.
    enum Route: Hashable {
        // @codegen:routes
    }

    private let dependencies: ParticipantDetailDependencies

    init(dependencies: ParticipantDetailDependencies) {
        self.dependencies = dependencies
    }

    func start() -> some View {
        ParticipantDetailView(dependencies: dependencies)
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
