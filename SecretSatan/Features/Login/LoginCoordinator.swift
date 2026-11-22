import SwiftUI

/// Entry point of the Login feature.
/// Builds the view through `LoginDependencies` and resolves the routes to the features opened from it.
@MainActor
final class LoginCoordinator: Coordinator {
    /// One case per feature that can be opened from Login.
    enum Route: Hashable {
        case home
        // @codegen:routes
    }

    private let dependencies: LoginDependencies

    init(dependencies: LoginDependencies = LoginDependencies()) {
        self.dependencies = dependencies
    }

    func start() -> some View {
        LoginView(dependencies: dependencies)
            .navigationDestination(for: Route.self) { route in
                self.destination(for: route)
            }
    }

    func destination(for route: Route) -> AnyView {
        switch route {
        case .home:
            return AnyView(HomeCoordinator().start())
        // @codegen:destinations
        }
    }
}
