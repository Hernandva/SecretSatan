import Foundation

/// Public data the app sends to add a participant (`addParticipant(eventId:_:)`) or to replace its data
/// (`updateParticipant(eventId:participantId:_:)`).
///
/// `name` is required, and so is `phone` or `guardianId`. An empty or blank `phone` or `family` is saved as `null`.
public protocol ParticipantsRequestProtocol: Sendable {
    var name: String { get }
    /// `nil` for participants without a phone, such as children: then `guardianId` is required.
    var phone: String? { get }
    /// Family unit. Participants with the same value are never assigned to each other in the draw.
    var family: String? { get }
    /// Participant of the same event, with a phone, who receives this participant's link.
    var guardianId: String? { get }
}
