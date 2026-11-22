import Foundation

/// Response of `POST /events/:id/participants` and `PUT /events/:id/participants/:pid`:
/// `{ id, name, phone, family, guardianId }`, with the missing fields as `null`.
/// Internal to SecretSatanData: the app only sees ParticipantsResponseProtocol.
struct ParticipantsResponseDAO: Decodable, Equatable, Sendable, ParticipantsResponseProtocol {
    let id: String
    let name: String
    let phone: String?
    let family: String?
    let guardianId: String?
}
