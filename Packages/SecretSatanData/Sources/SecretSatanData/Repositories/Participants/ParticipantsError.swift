import Foundation

/// Errors of the Participants repository.
public enum ParticipantsError: Error, Equatable, Sendable {
    /// There is no saved session, or it has expired: the user has to sign in again.
    case notSignedIn
}
