import Foundation

/// Public session the Auth repository returns after the backend accepts the provider's token.
public protocol AuthResponseProtocol: Sendable {
    /// Session token of the SecretSatan backend.
    var token: String { get }
    /// When `token` stops being valid.
    var expiresAt: Date { get }
    /// User of the session. The backend creates it the first time the user signs in.
    var user: any AuthUserProtocol { get }
}

/// Public user returned with a session.
public protocol AuthUserProtocol: Sendable {
    var id: String { get }
    var name: String? { get }
    var email: String? { get }
}
