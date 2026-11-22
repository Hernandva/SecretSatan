import Foundation

/// Body of `POST /auth/apple` and `POST /auth/google`: `{ idToken, nonce?, name? }`.
/// `nil` fields are left out of the JSON.
struct AuthTokenRequestDAO: Encodable, Equatable, Sendable {
    let idToken: String
    let nonce: String?
    let name: String?

    init(_ credential: AuthCredentialDAO) {
        self.idToken = credential.idToken
        self.nonce = credential.nonce
        self.name = credential.name
    }
}
