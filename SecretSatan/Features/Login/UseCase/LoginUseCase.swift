import Foundation
import SecretSatanData

/// Sign-in options of the Login screen.
enum LoginProvider: Sendable {
    case apple
    case google
}

protocol LoginUseCaseProtocol: Sendable {
    /// Signs the user in with `provider`. Returns `true` when the user is signed in and `false` when they closed the
    /// sign-in sheet. Throws when the sign-in fails.
    func execute(provider: LoginProvider) async throws -> Bool

    /// Returns `true` when the device keeps a session that has not expired.
    func hasValidSession() async throws -> Bool
}

/// Business logic of Login: signs in through the Auth repository, which also saves the session,
/// and tells whether a saved session is still valid.
struct LoginUseCase: LoginUseCaseProtocol {
    private struct Request: AuthRequestProtocol {
        let provider: AuthProvider
    }

    private let repository: any AuthRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `LoginDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: LoginDependencies) {
        self.repository = dependencies.resolveRepository()
    }

    func execute(provider: LoginProvider) async throws -> Bool {
        do {
            try await repository.signIn(Request(provider: Self.authProvider(for: provider)))
            return true
        } catch AuthError.canceled {
            return false
        }
    }

    func hasValidSession() async throws -> Bool {
        try await repository.currentSession() != nil
    }

    private static func authProvider(for provider: LoginProvider) -> AuthProvider {
        switch provider {
        case .apple: .apple
        case .google: .google
        }
    }
}
