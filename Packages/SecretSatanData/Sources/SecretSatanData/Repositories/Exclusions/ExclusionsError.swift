import Foundation

/// Errors of the Exclusions repository.
public enum ExclusionsError: Error, Equatable, Sendable {
    /// There is no saved session, or it has expired: the user has to sign in again.
    case notSignedIn
}
