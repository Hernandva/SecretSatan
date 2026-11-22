import Foundation
import SecretSatanData

protocol HomeUseCaseProtocol: Sendable {
    /// Returns the user of the saved session, or `nil` when the user has not signed in or the session expired.
    func execute() async throws -> HomeViewData.User?
}

/// Business logic of Home: reads the saved session from the Auth repository and returns only its user,
/// mapped out of the SecretSatanData types.
struct HomeUseCase: HomeUseCaseProtocol {
    private let repository: any AuthRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {
        self.repository = dependencies.resolveRepository()
    }

    func execute() async throws -> HomeViewData.User? {
        guard let session = try await repository.currentSession() else { return nil }
        return Self.user(from: session.user)
    }
}

private extension HomeUseCase {
    /// Maps the public user of the session into the data the view model adds to its ViewData.
    static func user(from user: any AuthUserProtocol) -> HomeViewData.User {
        HomeViewData.User(name: user.name, email: user.email)
    }
}
