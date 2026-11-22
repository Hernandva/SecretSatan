import Foundation
import SecretSatanData

/// Dependency injection container of ParticipantDetail: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class ParticipantDetailDependencies {
    /// Participant selected in the list of EventDetail, passed in by the route.
    private let participant: ParticipantDetailViewData.Participant
    private let repository: any ParticipantsRepositoryProtocol

    init(
        participant: ParticipantDetailViewData.Participant,
        repository: any ParticipantsRepositoryProtocol = ParticipantsRepository()
    ) {
        self.participant = participant
        self.repository = repository
    }

    func resolveParticipant() -> ParticipantDetailViewData.Participant {
        participant
    }

    func resolveRepository() -> any ParticipantsRepositoryProtocol {
        repository
    }

    func resolveUseCase() -> any ParticipantDetailUseCaseProtocol {
        ParticipantDetailUseCase(dependencies: self)
    }

    func resolveViewModel() -> ParticipantDetailViewModel {
        ParticipantDetailViewModel(dependencies: self)
    }
}
