import Foundation

/// Contact read from the device, internal to SecretSatanData: the app only sees ContactsResponseProtocol.
struct ContactsResponseDAO: Equatable, Sendable, ContactsResponseProtocol {
    let id: String
    let name: String
    let phones: [String]
}
