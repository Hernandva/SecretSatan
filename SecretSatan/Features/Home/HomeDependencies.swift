import Foundation
import SecretSatanData

/// Dependency injection container of Home: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class HomeDependencies {
    private let repository: any AuthRepositoryProtocol
    private let eventsRepository: any EventsRepositoryProtocol

    init(
        repository: any AuthRepositoryProtocol = AuthRepository(),
        eventsRepository: any EventsRepositoryProtocol = EventsRepository()
    ) {
        self.repository = repository
        self.eventsRepository = eventsRepository
    }

    func resolveRepository() -> any AuthRepositoryProtocol {
        repository
    }

    func resolveEventsRepository() -> any EventsRepositoryProtocol {
        eventsRepository
    }

    func resolveUseCase() -> any HomeUseCaseProtocol {
        HomeUseCase(dependencies: self)
    }

    func resolveEventsUseCase() -> any EventsUseCaseProtocol {
        EventsUseCase(dependencies: self)
    }

    func resolveCreateEventUseCase() -> any CreateEventUseCaseProtocol {
        CreateEventUseCase(dependencies: self)
    }

    func resolveNewEventViewModel() -> NewEventViewModel {
        NewEventViewModel(dependencies: self)
    }

    func resolveViewModel() -> HomeViewModel {
        HomeViewModel(dependencies: self)
    }
}
