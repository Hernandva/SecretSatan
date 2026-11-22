import Foundation
import SecretSatanData

/// Dependency injection container of EventDetail: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class EventDetailDependencies {
    /// Event selected in the list of Home, passed in by the route.
    private let event: EventDetailViewData.Event
    private let repository: any EventsRepositoryProtocol
    private let participantsRepository: any ParticipantsRepositoryProtocol

    init(
        event: EventDetailViewData.Event,
        repository: any EventsRepositoryProtocol = EventsRepository(),
        participantsRepository: any ParticipantsRepositoryProtocol = ParticipantsRepository()
    ) {
        self.event = event
        self.repository = repository
        self.participantsRepository = participantsRepository
    }

    func resolveEvent() -> EventDetailViewData.Event {
        event
    }

    func resolveRepository() -> any EventsRepositoryProtocol {
        repository
    }

    func resolveParticipantsRepository() -> any ParticipantsRepositoryProtocol {
        participantsRepository
    }

    func resolveUseCase() -> any EventDetailUseCaseProtocol {
        EventDetailUseCase(dependencies: self)
    }

    func resolveParticipantsUseCase() -> any EventParticipantsUseCaseProtocol {
        EventParticipantsUseCase(dependencies: self)
    }

    func resolveEditEventUseCase() -> any EditEventUseCaseProtocol {
        EditEventUseCase(dependencies: self)
    }

    func resolveNewParticipantUseCase() -> any NewParticipantUseCaseProtocol {
        NewParticipantUseCase(dependencies: self)
    }

    func resolveDeleteParticipantUseCase() -> any DeleteParticipantUseCaseProtocol {
        DeleteParticipantUseCase(dependencies: self)
    }

    func resolveDrawEventUseCase() -> any DrawEventUseCaseProtocol {
        DrawEventUseCase(dependencies: self)
    }

    func resolveViewModel() -> EventDetailViewModel {
        EventDetailViewModel(dependencies: self)
    }
}
