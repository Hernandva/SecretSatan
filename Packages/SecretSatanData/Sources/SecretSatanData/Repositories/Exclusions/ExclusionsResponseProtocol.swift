import Foundation

/// Public exclusion the Exclusions repository returns: `giverId` must not be assigned `receiverId` in the draw.
public protocol ExclusionsResponseProtocol: Sendable {
    var id: String { get }
    var giverId: String { get }
    var receiverId: String { get }
}
