import Foundation

protocol HomeUseCaseProtocol: Sendable {
    /// Returns only the data of the response. The view model adds it to its `HomeViewData`.
    func execute() async throws -> HomeViewData.Content
}

/// Business logic of Home.
/// When the feature needs a SecretSatanData repository, add a `resolve<Name>()` function to HomeDependencies,
/// resolve it in `init(dependencies:)` and map its public response protocol into the type this use case returns.
struct HomeUseCase: HomeUseCaseProtocol {
    /// Receives only the container and resolves what it needs from it.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {}

    func execute() async throws -> HomeViewData.Content {
        HomeViewData.Content()
    }
}
