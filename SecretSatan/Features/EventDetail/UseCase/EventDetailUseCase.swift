import Foundation

protocol EventDetailUseCaseProtocol: Sendable {
    /// Returns the event to show. The view model adds it to its `EventDetailViewData`.
    func execute() async throws -> EventDetailViewData.Event
}

/// Business logic of EventDetail: hands out the event selected in Home, passed in by the route.
/// To refresh it from the backend, resolve `EventsRepositoryProtocol` here and call `fetchEvent(id:)`.
struct EventDetailUseCase: EventDetailUseCaseProtocol {
    private let event: EventDetailViewData.Event

    /// Receives only the container and resolves what it needs from it.
    /// `EventDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: EventDetailDependencies) {
        self.event = dependencies.resolveEvent()
    }

    func execute() async throws -> EventDetailViewData.Event {
        event
    }
}
