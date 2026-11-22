import Foundation

protocol ParticipantDetailUseCaseProtocol: Sendable {
    /// Returns the participant to show. The view model adds it to its `ParticipantDetailViewData`.
    func execute() async throws -> ParticipantDetailViewData.Participant
}

/// Business logic of ParticipantDetail: hands out the participant selected in EventDetail, passed in by the route.
/// Its wards and exclusions come from `ParticipantWardsUseCase` and `ParticipantExclusionsUseCase`.
struct ParticipantDetailUseCase: ParticipantDetailUseCaseProtocol {
    private let participant: ParticipantDetailViewData.Participant

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.participant = dependencies.resolveParticipant()
    }

    func execute() async throws -> ParticipantDetailViewData.Participant {
        participant
    }
}
