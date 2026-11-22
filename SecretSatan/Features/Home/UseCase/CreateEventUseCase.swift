import Foundation
import SecretSatanData

/// What the "Nuevo evento" sheet sends to create an event. `name` and `date` are required.
struct CreateEventInput: Equatable, Sendable {
    let name: String
    let date: Date
    /// Minimum price of each gift, sent as the event's budget.
    let budget: Decimal?
}

protocol CreateEventUseCaseProtocol: Sendable {
    /// Creates the event and returns it as a row of the event list.
    func execute(_ input: CreateEventInput) async throws -> HomeViewData.Event
}

/// Creates an event through the Events repository and returns only the data the list shows,
/// mapped out of the SecretSatanData types.
struct CreateEventUseCase: CreateEventUseCaseProtocol {
    private struct Request: EventsRequestProtocol {
        let name: String
        let date: Date?
        let budget: Decimal?
    }

    private let repository: any EventsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {
        self.repository = dependencies.resolveEventsRepository()
    }

    func execute(_ input: CreateEventInput) async throws -> HomeViewData.Event {
        let request = Request(name: input.name, date: input.date, budget: input.budget)
        let response = try await repository.createEvent(request)
        return HomeViewData.Event(
            id: response.id,
            name: response.name,
            date: response.date,
            participantCount: response.participantCount,
            isDrawn: response.status == .drawn
        )
    }
}
