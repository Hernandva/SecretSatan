import Foundation

/// Response of `POST /auth/apple` and `POST /auth/google`: `{ token, expiresAt, user }`. It is also the session
/// saved by `AuthSessionStorage`, encoded with `expiresAt` as a Unix timestamp, which the decoder accepts too.
/// Internal to SecretSatanData: the app only sees AuthResponseProtocol.
struct AuthResponseDAO: Codable, Equatable, Sendable, AuthResponseProtocol {
    private enum CodingKeys: String, CodingKey {
        case token
        case expiresAt
        case userDAO = "user"
    }

    let token: String
    let expiresAt: Date
    let userDAO: AuthUserDAO

    var user: any AuthUserProtocol { userDAO }

    init(token: String, expiresAt: Date, userDAO: AuthUserDAO) {
        self.token = token
        self.expiresAt = expiresAt
        self.userDAO = userDAO
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
        userDAO = try container.decode(AuthUserDAO.self, forKey: .userDAO)
        expiresAt = try Self.decodeDate(from: container, forKey: .expiresAt)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(expiresAt.timeIntervalSince1970, forKey: .expiresAt)
        try container.encode(userDAO, forKey: .userDAO)
    }

    /// Reads an ISO 8601 date, with or without fractional seconds, or a Unix timestamp in seconds.
    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Date {
        if let seconds = try? container.decode(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: seconds)
        }
        let text = try container.decode(String.self, forKey: key)
        let withFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        if let date = (try? withFraction.parse(text)) ?? (try? Date.ISO8601FormatStyle().parse(text)) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "expiresAt is not an ISO 8601 date: \(text)"
        )
    }
}

/// `user` object of the session response.
struct AuthUserDAO: Codable, Equatable, Sendable, AuthUserProtocol {
    let id: String
    let name: String?
    let email: String?
}
