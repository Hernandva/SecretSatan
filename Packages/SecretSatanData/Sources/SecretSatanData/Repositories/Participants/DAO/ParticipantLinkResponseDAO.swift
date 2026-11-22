import Foundation

/// Response of `POST /events/:id/participants/:pid/link`:
/// `{ participantId, name, url, message, deliverToName, deliverToPhone }`.
/// Internal to SecretSatanData: the app only sees ParticipantLinkResponseProtocol.
struct ParticipantLinkResponseDAO: Decodable, Equatable, Sendable, ParticipantLinkResponseProtocol {
    let participantId: String
    let name: String
    let url: URL
    let message: String
    let deliverToName: String
    let deliverToPhone: String
}
