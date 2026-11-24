import Foundation

/// Public contact of the device that the Contacts repository returns.
public protocol ContactsResponseProtocol: Sendable {
    /// Identifier of the contact on the device.
    var id: String { get }
    /// Full name, e.g. "Lucía Martín". Never empty.
    var name: String { get }
    /// Phones of the contact as they are saved, in their order. Never empty.
    var phones: [String] { get }
}
