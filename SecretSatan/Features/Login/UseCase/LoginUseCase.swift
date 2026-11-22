import Foundation
import SecretSatanData

/// Sign-in options of the Login screen.
enum LoginProvider: Sendable {
    case apple
    case google
}

protocol LoginUseCaseProtocol: Sendable {
    /// Signs the user in with `provider`. Returns `nil` when the user closes the sign-in sheet.
    /// The view model adds the result to its `LoginViewData`.
    func execute(provider: LoginProvider) async throws -> LoginViewData.Session?
}

/// Business logic of Login: signs in through the Auth repository and maps its response.
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

    func execute(provider: LoginProvider) async throws -> LoginViewData.Session? {
        do {
            let response = try await repository.signIn(Request(provider: Self.authProvider(for: provider)))
            return LoginViewData.Session(
                userID: response.user.id,
                name: response.user.name,
                email: response.user.email
            )
        } catch AuthError.canceled {
            return nil
        }
    }

    private static func authProvider(for provider: LoginProvider) -> AuthProvider {
        switch provider {
        case .apple: .apple
        case .google: .google
        }
    }
}
