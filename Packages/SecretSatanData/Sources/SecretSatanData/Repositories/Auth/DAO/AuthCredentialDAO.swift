import Foundation

/// What a provider service returns after its sign-in sheet. Internal: it only travels to the backend.
struct AuthCredentialDAO: Equatable, Sendable {
    let provider: AuthProvider
    /// Identity token (a JWT) signed by the provider.
    let idToken: String
    /// Raw nonce whose SHA-256 hash went into the provider request, so the backend can check the token's `nonce`.
    let nonce: String?
    /// Full name of the user. Apple sends it only the first time the user signs in to the app.
    let name: String?
}
