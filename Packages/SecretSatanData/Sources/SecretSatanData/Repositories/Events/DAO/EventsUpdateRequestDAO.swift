import Foundation

/// Body of `PATCH /events/:id`: `{ name?, date? }`, with only the fields that change.
/// `date` is ISO 8601 when it is set, `null` when it is removed and left out when it stays the same.
/// Internal to SecretSatanData: never exposed to the app.
struct EventsUpdateRequestDAO: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case name
        case date
    }

    let name: String?
    let date: EventDateUpdate

    init(_ request: some EventsUpdateRequestProtocol) {
        name = request.name
        date = request.date
    }

    /// `true` when the request changes nothing, so it is not worth sending.
    var isEmpty: Bool {
        name == nil && date == .unchanged
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
    }
}
