import Foundation

/// Stage of an event.
public enum EventStatus: String, Sendable, Decodable {
    /// Before the draw.
    case draft
    /// After the draw.
    case drawn
}

/// Public event the Events repository returns from `GET /events`, `POST /events` and inside the detail.
public protocol EventsResponseProtocol: Sendable {
    var id: String { get }
    var name: String { get }
    /// When the gifts are exchanged, or `nil` when it is not set.
    var date: Date? { get }
    /// Spending limit of each gift, or `nil` when it is not set.
    var budget: Decimal? { get }
    var status: EventStatus { get }
    var participantCount: Int { get }
}

/// Public detail of an event, from `GET /events/:id`. It never includes the draw's assignments.
public protocol EventDetailResponseProtocol: Sendable {
    var event: any EventsResponseProtocol { get }
    var participants: [any EventParticipantResponseProtocol] { get }
    /// Pairs the draw must avoid. They come in both directions: creating one saves `A -> B` and `B -> A`.
    var exclusions: [any EventExclusionResponseProtocol] { get }
}

/// Public participant of an event.
public protocol EventParticipantResponseProtocol: Sendable {
    var id: String { get }
    var name: String { get }
    /// `nil` for participants without a phone, such as children.
    var phone: String? { get }
    var family: String? { get }
    /// Participant who receives this participant's link, e.g. the guardian of a child. `nil` when they get their own.
    var guardianId: String? { get }
}

/// Public exclusion: `giverId` must not be assigned `receiverId` in the draw.
public protocol EventExclusionResponseProtocol: Sendable {
    var id: String { get }
    var giverId: String { get }
    var receiverId: String { get }
}
