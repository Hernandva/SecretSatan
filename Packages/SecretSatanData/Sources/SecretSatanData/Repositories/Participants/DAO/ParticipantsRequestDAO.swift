import Foundation

/// Body of `POST /events/:id/participants` and `PUT /events/:id/participants/:pid`:
/// `{ name, phone?, family?, guardianId? }`.
/// The `POST` leaves out the missing fields; the `PUT` replaces every field, so it sends them as `null`.
/// Internal to SecretSatanData: never exposed to the app.
struct ParticipantsRequestDAO: Encodable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case name
        case phone
        case family
        case guardianId
    }

    let name: String
    let phone: String?
    let family: String?
    let guardianId: String?
    /// `true` to send the missing fields as `null` instead of leaving them out.
    let sendsEmptyFields: Bool

    init(_ request: some ParticipantsRequestProtocol, sendsEmptyFields: Bool) {
        name = request.name
        phone = request.phone
        family = request.family
        guardianId = request.guardianId
        self.sendsEmptyFields = sendsEmptyFields
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if sendsEmptyFields {
            try container.encode(phone, forKey: .phone)
            try container.encode(family, forKey: .family)
            try container.encode(guardianId, forKey: .guardianId)
        } else {
            try container.encodeIfPresent(phone, forKey: .phone)
            try container.encodeIfPresent(family, forKey: .family)
            try container.encodeIfPresent(guardianId, forKey: .guardianId)
        }
    }
}
