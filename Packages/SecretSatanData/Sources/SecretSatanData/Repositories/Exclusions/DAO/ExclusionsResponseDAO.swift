import Foundation

/// Each item of the response of `POST /events/:id/exclusions`: `{ id, giverId, receiverId }`.
/// Internal to SecretSatanData: the app only sees ExclusionsResponseProtocol.
struct ExclusionsResponseDAO: Decodable, Equatable, Sendable, ExclusionsResponseProtocol {
    let id: String
    let giverId: String
    let receiverId: String
}
