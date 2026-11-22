import Foundation
import SecretSatanData

protocol ParticipantExclusionsUseCaseProtocol: Sendable {
    /// Returns the participants the selected participant must not be assigned, as rows of "Exclusiones".
    func execute() async throws -> [ParticipantDetailViewData.Member]
}

/// Reads the exclusions of the selected participant through the Participants repository
/// (`GET /events/:id/participants/:pid/excluded`) and returns only the data the list shows.
struct ParticipantExclusionsUseCase: ParticipantExclusionsUseCaseProtocol {
    private let repository: any ParticipantsRepositoryProtocol
    private let eventId: String
    private let participantId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEventId()
        self.participantId = dependencies.resolveParticipant().id
    }

    func execute() async throws -> [ParticipantDetailViewData.Member] {
        try await repository.fetchExcluded(eventId: eventId, participantId: participantId)
            .map { ParticipantDetailViewData.Member(id: $0.id, name: $0.name) }
    }
}
