import Foundation
import SecretSatanData

/// One change the user makes to the event from EventDetail.
enum EditEventChange: Equatable, Sendable {
    case name(String)
    case date(Date)
}

protocol EditEventUseCaseProtocol: Sendable {
    /// Saves the change and returns the updated event.
    func execute(_ change: EditEventChange) async throws -> EventDetailViewData.Event
}

/// Changes the name or the date of the event through the Events repository (`PATCH /events/:id`) and returns
/// only the data the screen shows, mapped out of the SecretSatanData types.
struct EditEventUseCase: EditEventUseCaseProtocol {
    private struct Request: EventsUpdateRequestProtocol {
        var name: String?
        var date: EventDateUpdate = .unchanged
    }

    private let repository: any EventsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `EventDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: EventDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEvent().id
    }

    func execute(_ change: EditEventChange) async throws -> EventDetailViewData.Event {
        let response = try await repository.updateEvent(id: eventId, Self.request(for: change))
        return EventDetailViewData.Event(
            id: response.id,
            name: response.name,
            date: response.date,
            participantCount: response.participantCount
        )
    }
}

extension EditEventUseCase {
    /// Sends only the field that changes.
    private static func request(for change: EditEventChange) -> Request {
        switch change {
        case .name(let name):
            Request(name: name)
        case .date(let date):
            Request(date: .set(date))
        }
    }
}
