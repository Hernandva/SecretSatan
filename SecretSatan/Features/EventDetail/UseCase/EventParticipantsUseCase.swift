import Foundation
import SecretSatanData

protocol EventParticipantsUseCaseProtocol: Sendable {
    /// Returns the participants of the event, mapped into the rows of the participant list.
    func execute() async throws -> [EventDetailViewData.Participant]
}

/// Reads the participants of the selected event through the Events repository (`GET /events/:id`) and returns
/// only the data the list shows, mapped out of the SecretSatanData types.
struct EventParticipantsUseCase: EventParticipantsUseCaseProtocol {
    private let repository: any EventsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `EventDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: EventDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEvent().id
    }

    func execute() async throws -> [EventDetailViewData.Participant] {
        try await repository.fetchEvent(id: eventId).participants.map(Self.participant(from:))
    }
}

private extension EventParticipantsUseCase {
    /// Maps one participant of the repository into a row of the participant list.
    static func participant(from response: any EventParticipantResponseProtocol) -> EventDetailViewData.Participant {
        EventDetailViewData.Participant(
            id: response.id,
            name: response.name,
            initials: initials(of: response.name)
        )
    }

    /// First letter of the first two words, uppercased: "Lucía Martín" -> "LM", "Pablo" -> "P".
    static func initials(of name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()
    }
}
