import Foundation
import SecretSatanData

protocol DeleteEventUseCaseProtocol: Sendable {
    /// Deletes the event with `id`, with its participants, exclusions and links. Throws when the backend refuses.
    func execute(id: String) async throws
}

/// Deletes an event through the Events repository.
struct DeleteEventUseCase: DeleteEventUseCaseProtocol {
    private let repository: any EventsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `HomeDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: HomeDependencies) {
        self.repository = dependencies.resolveEventsRepository()
    }

    func execute(id: String) async throws {
        try await repository.deleteEvent(id: id)
    }
}
