import Foundation
import SecretSatanData

protocol ParticipantWardsUseCaseProtocol: Sendable {
    /// Returns the participants whose link the selected participant receives, as rows of "Protegidos".
    func execute() async throws -> [ParticipantDetailViewData.Member]
}

/// Reads the wards of the selected participant through the Participants repository
/// (`GET /events/:id/participants/:pid/wards`) and returns only the data the list shows.
struct ParticipantWardsUseCase: ParticipantWardsUseCaseProtocol {
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
        try await repository.fetchWards(eventId: eventId, participantId: participantId)
            .map { ParticipantDetailViewData.Member(id: $0.id, name: $0.name) }
    }
}
