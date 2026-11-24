import Foundation

/// Body of `PATCH /events/:id`: `{ name?, date?, message? }`, with only the fields that change.
/// `date` is ISO 8601 when it is set; `date` and `message` are `null` when removed and left out when they stay the
/// same.
/// Internal to SecretSatanData: never exposed to the app.
struct EventsUpdateRequestDAO: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case name
        case date
        case message
    }

    let name: String?
    let date: EventDateUpdate
    let message: EventMessageUpdate

    init(_ request: some EventsUpdateRequestProtocol) {
        name = request.name
        date = request.date
        message = request.message
    }

    /// `true` when the request changes nothing, so it is not worth sending.
    var isEmpty: Bool {
        name == nil && date == .unchanged && message == .unchanged
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        switch date {
        case .unchanged:
            break
        case .set(let value):
            try container.encode(value.formatted(.iso8601), forKey: .date)
        case .remove:
            try container.encodeNil(forKey: .date)
        }
        switch message {
        case .unchanged:
            break
        case .set(let value):
            try container.encode(value, forKey: .message)
        case .remove:
            try container.encodeNil(forKey: .message)
        }
    }
}
