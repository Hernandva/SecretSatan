import Foundation
import Observation

@MainActor
@Observable
final class EventDetailViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = EventDetailViewData()

    private let useCase: any EventDetailUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: EventDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
    }

    func load() async {
        state = .loading
        do {
            viewData.event = try await useCase.execute()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
