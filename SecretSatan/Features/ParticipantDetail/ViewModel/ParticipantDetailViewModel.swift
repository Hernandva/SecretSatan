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

    /// State of the change being saved from the name sheet.
    enum EditState: Equatable {
        case idle
        case saving
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var editState: EditState = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = ParticipantDetailViewData()

    /// `true` while the sheet to edit the name is shown.
    var isEditingName = false
    /// Name typed in the sheet. Starts as the current name.
    var draftName = ""

    private let useCase: any ParticipantDetailUseCaseProtocol
    private let wardsUseCase: any ParticipantWardsUseCaseProtocol
    private let exclusionsUseCase: any ParticipantExclusionsUseCaseProtocol
    private let editParticipantUseCase: any EditParticipantUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: ParticipantDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.wardsUseCase = dependencies.resolveWardsUseCase()
        self.exclusionsUseCase = dependencies.resolveExclusionsUseCase()
        self.editParticipantUseCase = dependencies.resolveEditParticipantUseCase()
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

    // MARK: - Name

    /// "Editar" beside the name: opens the sheet with the current name.
    func startEditingName() {
        draftName = viewData.participant?.name ?? ""
        editState = .idle
        isEditingName = true
    }

    /// `true` when the typed name is not empty, differs from the current one and nothing is being saved.
    var canSaveName: Bool {
        guard let newName = trimmedDraftName, editState != .saving else { return false }
        return newName != viewData.participant?.name
    }

    /// Saves the typed name, puts the updated participant in `viewData.participant` and closes the sheet.
    func saveName() async {
        guard canSaveName, let newName = trimmedDraftName, let participant = viewData.participant else { return }
        editState = .saving
        do {
            viewData.participant = try await editParticipantUseCase.execute(name: newName, of: participant)
            editState = .idle
            isEditingName = false
        } catch {
            editState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Actions

    /// "Editar" beside the phone. The sheet to change the phone is not built yet.
    func startEditingPhone() {}

    /// "Añadir" in "Protegidos". The sheet to pick a ward is not built yet.
    func startAddingWard() {}

    /// "Añadir" in "Exclusiones". The sheet to pick an exclusion is not built yet.
    func startAddingExclusion() {}

    // MARK: - Private

    /// The typed name without surrounding spaces, or `nil` when it is empty.
    private var trimmedDraftName: String? {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
