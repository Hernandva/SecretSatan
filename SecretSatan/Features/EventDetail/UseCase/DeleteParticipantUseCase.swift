import Foundation
import SecretSatanData

/// Errors of `DeleteParticipantUseCase` that the screen can show.
enum DeleteParticipantError: Error, Equatable {
    /// The backend refused to remove the participant, with its message,
    /// e.g. "El sorteo ya se hizo; no se pueden quitar participantes."
    case rejected(String)
}

protocol DeleteParticipantUseCaseProtocol: Sendable {
    /// Removes the participant with `id` from the event, with its exclusions.
    /// Throws `DeleteParticipantError.rejected` when the backend refuses, e.g. after the draw.
    func execute(id: String) async throws
}

/// Removes a participant from the selected event through the Participants repository.
struct DeleteParticipantUseCase: DeleteParticipantUseCaseProtocol {
    private let repository: any ParticipantsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `EventDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: EventDetailDependencies) {
        self.repository = dependencies.resolveParticipantsRepository()
        self.eventId = dependencies.resolveEvent().id
    }

    func execute(id: String) async throws {
        do {
            try await repository.deleteParticipant(eventId: eventId, participantId: id)
        } catch NetworkError.server(_, let reason) {
            throw DeleteParticipantError.rejected(reason)
        }
    }
}
