import Foundation

/// Public data the app sends to create an event with `EventsRepositoryProtocol.createEvent(_:)`.
/// Only `name` is required; `message` defaults to `nil`.
public protocol EventsRequestProtocol: Sendable {
    var name: String { get }
    /// When the gifts are exchanged.
    var date: Date? { get }
    /// Spending limit of each gift.
    var budget: Decimal? { get }
    /// Message of the organiser for the participants, or `nil` to leave it out.
    var message: String? { get }
}

public extension EventsRequestProtocol {
    var message: String? { nil }
}
