import Foundation

/// One event of `GET /events`, the response of `POST /events` and the `event` of the detail:
/// `{ id, name, date, budget, message, status, participantCount }`, with `date`, `budget` and `message` as `null`
/// (or missing) when not set.
/// Internal to SecretSatanData: the app only sees EventsResponseProtocol.
struct EventsResponseDAO: Decodable, Equatable, Sendable, EventsResponseProtocol {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case date
        case budget
        case message
        case status
        case participantCount
    }

    let id: String
    let name: String
    let date: Date?
    let budget: Decimal?
    let message: String?
    let status: EventStatus
    let participantCount: Int

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        budget = try container.decodeIfPresent(Decimal.self, forKey: .budget)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        status = try container.decode(EventStatus.self, forKey: .status)
        participantCount = try container.decode(Int.self, forKey: .participantCount)
        date = try Self.decodeDate(from: container, forKey: .date)
    }
}

private extension EventsResponseDAO {
    /// Reads an ISO 8601 date, with or without fractional seconds, or `nil` when it is missing or `null`.
    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Date? {
        guard let text = try container.decodeIfPresent(String.self, forKey: key) else { return nil }
        let withFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        if let date = (try? withFraction.parse(text)) ?? (try? Date.ISO8601FormatStyle().parse(text)) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "date is not an ISO 8601 date: \(text)"
        )
    }
}
