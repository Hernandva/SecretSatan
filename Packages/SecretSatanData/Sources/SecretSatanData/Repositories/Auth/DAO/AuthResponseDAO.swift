import Foundation

/// Response of `POST /auth/apple` and `POST /auth/google`: `{ token, expiresAt, user }`.
/// Internal to SecretSatanData: the app only sees AuthResponseProtocol.
struct AuthResponseDAO: Decodable, Equatable, Sendable, AuthResponseProtocol {
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
struct AuthUserDAO: Decodable, Equatable, Sendable, AuthUserProtocol {
    let id: String
    let name: String?
    let email: String?
}
