import Foundation
import Observation

@MainActor
@Observable
final class EventDetailViewModel {
    enum State: Equatable {
        case idle
        /// `viewData.event` is already set; the participants are loading.
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = EventDetailViewData()

    private let useCase: any EventDetailUseCaseProtocol
    private let participantsUseCase: any EventParticipantsUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: EventDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.participantsUseCase = dependencies.resolveParticipantsUseCase()
    }

    /// Shows the event passed in by Home right away, then loads its participants.
    func load() async {
        state = .loading
        do {
            viewData.event = try await useCase.execute()
            viewData.participants = try await participantsUseCase.execute()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
