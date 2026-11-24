import Foundation

/// Errors of the Events repository.
public enum EventsError: Error, Equatable, Sendable {
    /// There is no saved session, or it has expired: the user has to sign in again.
    case notSignedIn
    /// `updateEvent(id:_:)` was called without a new name, date or message, so nothing was sent.
    case nothingToUpdate
}
