import Foundation

/// Wire format of the Auth response. Internal to SecretSatanData: the app only sees AuthResponseProtocol.
struct AuthResponseDAO: Decodable, Sendable, AuthResponseProtocol {}
