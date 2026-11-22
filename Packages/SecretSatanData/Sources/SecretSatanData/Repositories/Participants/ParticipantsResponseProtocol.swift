import Foundation

/// Public participant the Participants repository returns after adding or editing one.
public protocol ParticipantsResponseProtocol: Sendable {
    var id: String { get }
    var name: String { get }
    /// `nil` for participants without a phone, such as children.
    var phone: String? { get }
    var family: String? { get }
    /// Participant who receives this participant's link, e.g. the guardian of a child. `nil` when they get their own.
    var guardianId: String? { get }
}
