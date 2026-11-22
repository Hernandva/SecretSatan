import Foundation
import SecretSatanData

protocol EventsUseCaseProtocol: Sendable {
    /// Returns the user's events, newest first, mapped into the rows of the event list.
    func execute() async throws -> [HomeViewData.Event]
}

/// Lists the user's events through the Events repository and returns only the data the list shows,
/// mapped out of the SecretSatanData types.
struct EventsUseCase: EventsUseCaseProtocol {
    private let repository: any EventsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {
        self.repository = dependencies.resolveEventsRepository()
    }

    func execute() async throws -> [HomeViewData.Event] {
        try await repository.fetchEvents().map(Self.event(from:))
    }
}

private extension EventsUseCase {
    /// Maps one event of the repository into a row of the event list.
    static func event(from response: any EventsResponseProtocol) -> HomeViewData.Event {
        HomeViewData.Event(
            id: response.id,
            name: response.name,
            participantCount: response.participantCount
        )
    }
}
