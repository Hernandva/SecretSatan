import Foundation
import SecretSatanData

/// Errors of `DeleteExclusionUseCase` that the screen can show.
enum DeleteExclusionError: Error, Equatable {
    /// The backend refused to remove the exclusion, with its message.
    case rejected(String)
}

protocol DeleteExclusionUseCaseProtocol: Sendable {
    /// Removes the exclusion between the selected participant and `receiverId`, in both directions.
    /// Throws `DeleteExclusionError.rejected` when the backend refuses.
    func execute(receiverId: String) async throws
}

/// Removes an exclusion of the selected participant. The list of exclusions has no exclusion ids, so it first reads
/// the event's exclusions through the Events repository (`GET /events/:id`) to find the id, then removes it through
/// the Exclusions repository (`DELETE /events/:id/exclusions/:xid`), which removes both directions.
struct DeleteExclusionUseCase: DeleteExclusionUseCaseProtocol {
    private let eventsRepository: any EventsRepositoryProtocol
    private let exclusionsRepository: any ExclusionsRepositoryProtocol
    private let eventId: String
    private let participantId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.eventsRepository = dependencies.resolveEventsRepository()
        self.exclusionsRepository = dependencies.resolveExclusionsRepository()
        self.eventId = dependencies.resolveEventId()
        self.participantId = dependencies.resolveParticipant().id
    }

    func execute(receiverId: String) async throws {
        do {
            let exclusions = try await eventsRepository.fetchEvent(id: eventId).exclusions
            // Either direction works: the backend removes both. None left means it is already gone.
            guard let exclusion = exclusions.first(where: { connects($0, to: receiverId) }) else { return }
            try await exclusionsRepository.deleteExclusion(eventId: eventId, exclusionId: exclusion.id)
        } catch NetworkError.server(_, let reason) {
            throw DeleteExclusionError.rejected(reason)
        }
    }
}

private extension DeleteExclusionUseCase {
    /// `true` when `exclusion` joins the selected participant and `receiverId`, in either direction.
    func connects(_ exclusion: any EventExclusionResponseProtocol, to receiverId: String) -> Bool {
        (exclusion.giverId == participantId && exclusion.receiverId == receiverId)
            || (exclusion.giverId == receiverId && exclusion.receiverId == participantId)
    }
}
