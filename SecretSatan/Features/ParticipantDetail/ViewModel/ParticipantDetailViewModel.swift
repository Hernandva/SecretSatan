import Foundation
import Observation

@MainActor
@Observable
final class ParticipantDetailViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = ParticipantDetailViewData()

    private let useCase: any ParticipantDetailUseCaseProtocol
    private let wardsUseCase: any ParticipantWardsUseCaseProtocol
    private let exclusionsUseCase: any ParticipantExclusionsUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: ParticipantDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.wardsUseCase = dependencies.resolveWardsUseCase()
        self.exclusionsUseCase = dependencies.resolveExclusionsUseCase()
    }

    /// Shows the participant passed in by EventDetail, then loads its wards and exclusions at the same time.
    func load() async {
        state = .loading
        do {
            viewData.participant = try await useCase.execute()
            async let wards = wardsUseCase.execute()
            async let exclusions = exclusionsUseCase.execute()
            viewData.wards = try await wards
            viewData.exclusions = try await exclusions
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Actions

    /// "Editar" beside the name. The sheet to rename the participant is not built yet.
    func startEditingName() {}

    /// "Editar" beside the phone. The sheet to change the phone is not built yet.
    func startEditingPhone() {}

    /// "Añadir" in "Protegidos". The sheet to pick a ward is not built yet.
    func startAddingWard() {}

    /// "Añadir" in "Exclusiones". The sheet to pick an exclusion is not built yet.
    func startAddingExclusion() {}
}
