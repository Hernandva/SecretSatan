import Foundation

/// Errors of the Events repository.
public enum EventsError: Error, Equatable, Sendable {
    /// There is no saved session, or it has expired: the user has to sign in again.
    case notSignedIn
}
