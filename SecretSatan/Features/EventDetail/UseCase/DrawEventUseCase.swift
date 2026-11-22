import Foundation
import SecretSatanData

/// Errors of `DrawEventUseCase` that the screen can show.
enum DrawEventError: Error, Equatable {
    /// The backend refused the draw, with its message, e.g. when it has already been made.
    case rejected(String)
}

protocol DrawEventUseCaseProtocol: Sendable {
    /// Draws the event and returns the result. The view model adds it to its `EventDetailViewData`.
    /// Throws `DrawEventError.rejected` when the backend refuses.
    func execute() async throws -> EventDetailViewData.Draw
}

/// Draws the selected event through the Events repository. The backend never says who gives to whom.
struct DrawEventUseCase: DrawEventUseCaseProtocol {
    private let repository: any EventsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `EventDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: EventDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEvent().id
    }

    func execute() async throws -> EventDetailViewData.Draw {
        do {
            let response = try await repository.drawEvent(id: eventId)
            return EventDetailViewData.Draw(assignments: response.assignments)
        } catch NetworkError.server(_, let reason) {
            throw DrawEventError.rejected(reason)
        }
    }
}
