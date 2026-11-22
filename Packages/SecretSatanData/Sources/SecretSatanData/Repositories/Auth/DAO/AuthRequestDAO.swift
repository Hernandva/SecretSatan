import Foundation

/// Wire format of the Auth request. Internal to SecretSatanData: never exposed to the app.
struct AuthRequestDAO: Encodable, Sendable {
    init(_ request: some AuthRequestProtocol) {
        // Copy the fields of the request protocol into encodable properties.
    }
}
