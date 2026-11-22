import Foundation

/// Sign-in request handed to a provider service. Internal to SecretSatanData: never exposed to the app.
struct AuthRequestDAO: Encodable, Sendable {
    let provider: AuthProvider

    init(_ request: some AuthRequestProtocol) {
        self.provider = request.provider
    }
}
