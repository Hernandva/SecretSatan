import Foundation
import SecretSatanData

/// Errors of `DeleteWardUseCase` that the screen can show.
enum DeleteWardError: Error, Equatable {
    /// The backend refused to remove the ward, with its message, e.g. after the draw.
    case rejected(String)
}

protocol DeleteWardUseCaseProtocol: Sendable {
    /// Removes the ward with `id` from the event, with its exclusions. A ward has no phone of its own, so it can't
    /// stay in the event without its guardian. Throws `DeleteWardError.rejected` when the backend refuses.
    func execute(id: String) async throws
}

/// Removes a ward of the selected participant from the event through the Participants repository
/// (`DELETE /events/:id/participants/:pid`).
struct DeleteWardUseCase: DeleteWardUseCaseProtocol {
    private let repository: any ParticipantsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEventId()
    }

    func execute(id: String) async throws {
        do {
            try await repository.deleteParticipant(eventId: eventId, participantId: id)
        } catch NetworkError.server(_, let reason) {
            throw DeleteWardError.rejected(reason)
        }
    }
}
