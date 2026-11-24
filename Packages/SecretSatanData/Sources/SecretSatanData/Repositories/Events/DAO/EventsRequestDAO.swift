import Foundation

/// Body of `POST /events`: `{ name, date?, budget?, message? }`, with `date` as ISO 8601 and the missing fields left out.
/// Internal to SecretSatanData: never exposed to the app.
struct EventsRequestDAO: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case name
        case date
        case budget
        case message
    }

    let name: String
    let date: Date?
    let budget: Decimal?
    let message: String?

    init(_ request: some EventsRequestProtocol) {
        name = request.name
        date = request.date
        budget = request.budget
        message = request.message
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(date?.formatted(.iso8601), forKey: .date)
        try container.encodeIfPresent(budget, forKey: .budget)
        try container.encodeIfPresent(message, forKey: .message)
    }
}
