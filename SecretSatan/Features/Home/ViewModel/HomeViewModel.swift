import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        /// The session was read. `viewData.user` is `nil` when there is no valid session.
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = HomeViewData()

    private let useCase: any HomeUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: HomeDependencies) {
        self.useCase = dependencies.resolveUseCase()
    }

    /// Reads the saved session and adds its user to `viewData.user`.
    func load() async {
        guard state != .loading else { return }
        state = .loading
        do {
            viewData.user = try await useCase.execute()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
