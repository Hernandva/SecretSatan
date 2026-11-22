import Foundation
import SecretSatanData

/// Dependency injection container of ParticipantDetail: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class ParticipantDetailDependencies {
    /// Event the participant belongs to, passed in by EventDetail.
    private let eventId: String
    /// Participant selected in the list of EventDetail, passed in by the route.
    private let participant: ParticipantDetailViewData.Participant
    private let repository: any ParticipantsRepositoryProtocol
    /// Reads the participants of the event, for the "Nueva exclusión" sheet.
    private let eventsRepository: any EventsRepositoryProtocol
    /// Creates the exclusions picked in the "Nueva exclusión" sheet.
    private let exclusionsRepository: any ExclusionsRepositoryProtocol

    init(
        eventId: String,
        participant: ParticipantDetailViewData.Participant,
        repository: any ParticipantsRepositoryProtocol = ParticipantsRepository(),
        eventsRepository: any EventsRepositoryProtocol = EventsRepository(),
        exclusionsRepository: any ExclusionsRepositoryProtocol = ExclusionsRepository()
    ) {
        self.eventId = eventId
        self.participant = participant
        self.repository = repository
        self.eventsRepository = eventsRepository
        self.exclusionsRepository = exclusionsRepository
    }

    func resolveEventId() -> String {
        eventId
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

    func resolveEventsRepository() -> any EventsRepositoryProtocol {
        eventsRepository
    }

    func resolveExclusionsRepository() -> any ExclusionsRepositoryProtocol {
        exclusionsRepository
    }

    func resolveAddExclusionUseCase() -> any AddExclusionUseCaseProtocol {
        AddExclusionUseCase(dependencies: self)
    }

    func resolveExclusionCandidatesUseCase() -> any ExclusionCandidatesUseCaseProtocol {
        ExclusionCandidatesUseCase(dependencies: self)
    }

    func resolveWardsUseCase() -> any ParticipantWardsUseCaseProtocol {
        ParticipantWardsUseCase(dependencies: self)
    }

    func resolveExclusionsUseCase() -> any ParticipantExclusionsUseCaseProtocol {
        ParticipantExclusionsUseCase(dependencies: self)
    }

    func resolveEditParticipantUseCase() -> any EditParticipantUseCaseProtocol {
        EditParticipantUseCase(dependencies: self)
    }

    func resolveAddWardUseCase() -> any AddWardUseCaseProtocol {
        AddWardUseCase(dependencies: self)
    }

    func resolveViewModel() -> ParticipantDetailViewModel {
        ParticipantDetailViewModel(dependencies: self)
    }
}
