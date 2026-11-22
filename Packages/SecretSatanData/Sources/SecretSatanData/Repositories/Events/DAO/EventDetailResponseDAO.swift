import Foundation

/// Response of `GET /events/:id`: `{ event, participants, exclusions }`.
/// Internal to SecretSatanData: the app only sees EventDetailResponseProtocol.
struct EventDetailResponseDAO: Decodable, Equatable, Sendable, EventDetailResponseProtocol {
    private enum CodingKeys: String, CodingKey {
        case eventDAO = "event"
        case participantDAOs = "participants"
        case exclusionDAOs = "exclusions"
    }

    let eventDAO: EventsResponseDAO
    let participantDAOs: [EventParticipantDAO]
    let exclusionDAOs: [EventExclusionDAO]

    var event: any EventsResponseProtocol { eventDAO }
    var participants: [any EventParticipantResponseProtocol] { participantDAOs }
    var exclusions: [any EventExclusionResponseProtocol] { exclusionDAOs }
}

/// One of the `participants` of the detail.
struct EventParticipantDAO: Decodable, Equatable, Sendable, EventParticipantResponseProtocol {
    let id: String
    let name: String
    let phone: String?
    let family: String?
    let guardianId: String?
}

/// One of the `exclusions` of the detail.
struct EventExclusionDAO: Decodable, Equatable, Sendable, EventExclusionResponseProtocol {
    let id: String
    let giverId: String
    let receiverId: String
}
