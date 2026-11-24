import Foundation

/// Errors of the Contacts repository.
public enum ContactsError: Error, Equatable, Sendable {
    /// The user has not allowed access to the contacts, or it is restricted. It can be changed in Settings.
    case accessDenied
}
