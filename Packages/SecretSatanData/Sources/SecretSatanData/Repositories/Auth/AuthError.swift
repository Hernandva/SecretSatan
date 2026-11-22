import Foundation

/// Errors of the Auth repository.
public enum AuthError: Error, Equatable, Sendable {
    /// No service is registered for this provider in `AuthRepository`.
    case unsupportedProvider(AuthProvider)
    /// The user closed the provider's sign-in sheet.
    case canceled
    /// The provider answered without the data a sign-in needs (for example, no identity token).
    case invalidCredential
}
