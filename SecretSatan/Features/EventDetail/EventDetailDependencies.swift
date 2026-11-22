import Foundation

/// Dependency injection container of EventDetail: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class EventDetailDependencies {
    /// Event selected in the list of Home, passed in by the route.
    private let event: EventDetailViewData.Event

    init(event: EventDetailViewData.Event) {
        self.event = event
    }

    func resolveEvent() -> EventDetailViewData.Event {
        event
    }

    func resolveUseCase() -> any EventDetailUseCaseProtocol {
        EventDetailUseCase(dependencies: self)
    }

    func resolveViewModel() -> EventDetailViewModel {
        EventDetailViewModel(dependencies: self)
    }
}
