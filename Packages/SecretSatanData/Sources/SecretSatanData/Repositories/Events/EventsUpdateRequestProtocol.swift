import Foundation

/// Public data the app sends to change an event with `EventsRepositoryProtocol.updateEvent(id:_:)`.
/// Only what it changes is sent (`PATCH`): the rest of the event stays as it was.
/// Every field defaults to "keep it", so a request declares only the ones it changes.
public protocol EventsUpdateRequestProtocol: Sendable {
    /// New name, or `nil` to keep the current one.
    var name: String? { get }
    /// Whether to keep, set or remove the date.
    var date: EventDateUpdate { get }
    /// Whether to keep, set or remove the message.
    var message: EventMessageUpdate { get }
}

public extension EventsUpdateRequestProtocol {
    var name: String? { nil }
    var date: EventDateUpdate { .unchanged }
    var message: EventMessageUpdate { .unchanged }
}

/// Change to the date of an event. `Date?` can't tell "keep it" from "remove it", so it has its own type.
public enum EventDateUpdate: Equatable, Sendable {
    /// The date is not sent: it stays as it was.
    case unchanged
    /// Sends the new date.
    case set(Date)
    /// Sends `"date": null`: the event has no date anymore.
    case remove
}

/// Change to the message of an event. `String?` can't tell "keep it" from "remove it", so it has its own type.
public enum EventMessageUpdate: Equatable, Sendable {
    /// The message is not sent: it stays as it was.
    case unchanged
    /// Sends the new message.
    case set(String)
    /// Sends `"message": null`: the event has no message anymore.
    case remove
}
