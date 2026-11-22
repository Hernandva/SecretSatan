import Foundation
import SecretSatanData

protocol ExclusionCandidatesUseCaseProtocol: Sendable {
    /// Returns the participants of the event that can be added as an exclusion of the selected participant,
    /// leaving out the ones whose ids are in `excludedIds`.
    func execute(excluding excludedIds: Set<String>) async throws -> [ParticipantDetailViewData.Member]
}

/// Reads the participants of the event through the Events repository (`GET /events/:id`) and returns, as rows of the
/// "Nueva exclusión" sheet, the ones that are not in `excludedIds`.
struct ExclusionCandidatesUseCase: ExclusionCandidatesUseCaseProtocol {
    private let repository: any EventsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.repository = dependencies.resolveEventsRepository()
        self.eventId = dependencies.resolveEventId()
    }

    func execute(excluding excludedIds: Set<String>) async throws -> [ParticipantDetailViewData.Member] {
        try await repository.fetchEvent(id: eventId).participants
            .filter { !excludedIds.contains($0.id) }
            .map { ParticipantDetailViewData.Member(id: $0.id, name: $0.name) }
    }
}
