import Foundation

protocol LoginUseCaseProtocol: Sendable {
    /// Returns only the data of the response. The view model adds it to its `LoginViewData`.
    func execute() async throws -> LoginViewData.Content
}

/// Business logic of Login.
/// When the feature needs a SecretSatanData repository, add a `resolve<Name>()` function to LoginDependencies,
/// resolve it in `init(dependencies:)` and map its public response protocol into the type this use case returns.
struct LoginUseCase: LoginUseCaseProtocol {
    /// Receives only the container and resolves what it needs from it.
    /// `LoginDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: LoginDependencies) {}

    func execute() async throws -> LoginViewData.Content {
        LoginViewData.Content()
    }
}
