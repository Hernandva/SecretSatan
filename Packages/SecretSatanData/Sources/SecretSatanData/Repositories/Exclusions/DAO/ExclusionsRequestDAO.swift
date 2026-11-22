import Foundation

/// Body of `POST /events/:id/exclusions`: `{ giverId, receiverId }`.
/// Internal to SecretSatanData: never exposed to the app.
struct ExclusionsRequestDAO: Encodable, Sendable {
    let giverId: String
    let receiverId: String

    init(_ request: some ExclusionsRequestProtocol) {
        giverId = request.giverId
        receiverId = request.receiverId
    }
}
