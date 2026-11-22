import Foundation

/// Public participant the Participants repository returns after adding or editing one, and in the lists of
/// `fetchWards(eventId:participantId:)` and `fetchExcluded(eventId:participantId:)`.
public protocol ParticipantsResponseProtocol: Sendable {
    var id: String { get }
    var name: String { get }
    /// `nil` for participants without a phone, such as children.
    var phone: String? { get }
    /// Participant who receives this participant's link, e.g. the guardian of a child. `nil` when they get their own.
    var guardianId: String? { get }
}

/// Public link of a participant, from `POST /events/:id/participants/:pid/link`: the page where it sees who it
/// gives a gift to, and the message to send it. The link only opens once.
public protocol ParticipantLinkResponseProtocol: Sendable {
    var participantId: String { get }
    /// Name of the participant the link belongs to.
    var name: String { get }
    var url: URL { get }
    /// Text ready to send, with the link at the end.
    var message: String { get }
    /// Who receives the message: the participant itself or, for a ward, its guardian.
    var deliverToName: String { get }
    /// Phone the message goes to.
    var deliverToPhone: String { get }
}
