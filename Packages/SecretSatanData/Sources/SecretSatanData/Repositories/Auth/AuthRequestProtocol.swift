import Foundation

/// Identity providers the Auth repository can sign in with.
public enum AuthProvider: String, Codable, CaseIterable, Sendable {
    case apple
    case google
}

/// Public data the app must provide to sign in through the Auth repository.
public protocol AuthRequestProtocol: Sendable {
    /// Provider that performs the sign-in.
    var provider: AuthProvider { get }
}
