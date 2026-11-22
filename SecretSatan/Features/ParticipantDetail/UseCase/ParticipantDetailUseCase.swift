import Foundation

protocol ParticipantDetailUseCaseProtocol: Sendable {
    /// Returns the participant to show. The view model adds it to its `ParticipantDetailViewData`.
    func execute() async throws -> ParticipantDetailViewData.Participant

    /// Returns `true` when the event has been drawn. The view model adds it to its `ParticipantDetailViewData`.
    func executeIsDrawn() -> Bool
}

/// Business logic of ParticipantDetail: hands out the participant selected in EventDetail and whether its event
/// has been drawn, both passed in by the route.
/// Its wards and exclusions come from `ParticipantWardsUseCase` and `ParticipantExclusionsUseCase`.
struct ParticipantDetailUseCase: ParticipantDetailUseCaseProtocol {
    private let participant: ParticipantDetailViewData.Participant
    private let isDrawn: Bool

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.participant = dependencies.resolveParticipant()
        self.isDrawn = dependencies.resolveIsDrawn()
    }

    func execute() async throws -> ParticipantDetailViewData.Participant {
        participant
    }

    func executeIsDrawn() -> Bool {
        isDrawn
    }
}
