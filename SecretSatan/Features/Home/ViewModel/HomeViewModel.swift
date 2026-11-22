import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        /// The session and the events were read. `viewData.user` is `nil` when there is no valid session,
        /// and then `viewData.events` stays empty.
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = HomeViewData()

    /// `true` after a delete fails, so the view shows an alert. The view sets it back to `false` when it closes.
    var deleteFailed = false

    private let useCase: any HomeUseCaseProtocol
    private let eventsUseCase: any EventsUseCaseProtocol
    private let deleteEventUseCase: any DeleteEventUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: HomeDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.eventsUseCase = dependencies.resolveEventsUseCase()
        self.deleteEventUseCase = dependencies.resolveDeleteEventUseCase()
    }

    /// Removes the event from the list at once and deletes it on the backend. If that fails, the event goes back to
    /// its place and `deleteFailed` turns on.
    func deleteEvent(_ event: HomeViewData.Event) async {
        guard let index = viewData.events.firstIndex(of: event) else { return }
        viewData.events.remove(at: index)
        do {
            try await deleteEventUseCase.execute(id: event.id)
        } catch {
            viewData.events.insert(event, at: min(index, viewData.events.count))
            deleteFailed = true
        }
    }

    /// Reads the saved session into `viewData.user` and, with a session, the user's events into `viewData.events`.
    func load() async {
        guard state != .loading else { return }
        state = .loading
        do {
            viewData.user = try await useCase.execute()
            if viewData.user != nil {
                viewData.events = try await eventsUseCase.execute()
            }
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Reads the events again, e.g. after the "Nuevo evento" sheet closes. Keeps the list on screen while it loads,
    /// and keeps the current one if the request fails.
    func reloadEvents() async {
        guard state == .loaded, viewData.user != nil else { return }
        if let events = try? await eventsUseCase.execute() {
            viewData.events = events
        }
    }
}
