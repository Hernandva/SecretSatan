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

    private let useCase: any HomeUseCaseProtocol
    private let eventsUseCase: any EventsUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: HomeDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.eventsUseCase = dependencies.resolveEventsUseCase()
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
}
