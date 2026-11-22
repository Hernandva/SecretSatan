import Foundation

/// Public data the app sends to create an event with `EventsRepositoryProtocol.createEvent(_:)`.
/// Only `name` is required.
public protocol EventsRequestProtocol: Sendable {
    var name: String { get }
    /// When the gifts are exchanged.
    var date: Date? { get }
    /// Spending limit of each gift.
    var budget: Decimal? { get }
}
