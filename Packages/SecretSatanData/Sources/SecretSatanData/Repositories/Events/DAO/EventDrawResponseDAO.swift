import Foundation

/// Response of `POST /events/:id/draw`: `{ status, assignments }`.
/// Internal to SecretSatanData: the app only sees EventDrawResponseProtocol.
struct EventDrawResponseDAO: Decodable, Equatable, Sendable, EventDrawResponseProtocol {
    let status: EventStatus
    let assignments: Int
}
