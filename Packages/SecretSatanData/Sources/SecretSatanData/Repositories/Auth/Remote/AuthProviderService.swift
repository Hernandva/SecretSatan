import Foundation

/// Internal service protocol every identity provider conforms to. `AuthRepository` forwards each sign-in to the
/// service registered for the requested provider, then sends the credential to the backend. Adding a provider
/// means adding one service in `Remote/<Provider>/` and registering it in `AuthRepository.init()`.
protocol AuthProviderService: Sendable {
    /// Provider this service signs in with.
    var provider: AuthProvider { get }

    /// Shows the provider's sign-in UI and returns its credential. Throws `AuthError.canceled` when the user
    /// closes it.
    func signIn(_ request: AuthRequestDAO) async throws -> AuthCredentialDAO
}
