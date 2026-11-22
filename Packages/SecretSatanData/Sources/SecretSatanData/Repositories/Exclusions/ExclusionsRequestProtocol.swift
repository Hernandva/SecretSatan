import Foundation

/// Public data the app sends to create an exclusion (`createExclusion(eventId:_:)`): the two participants of the
/// event who must not be assigned to each other in the draw.
///
/// The backend saves it in both directions, so which one is the giver and which one the receiver doesn't matter.
public protocol ExclusionsRequestProtocol: Sendable {
    var giverId: String { get }
    var receiverId: String { get }
}
