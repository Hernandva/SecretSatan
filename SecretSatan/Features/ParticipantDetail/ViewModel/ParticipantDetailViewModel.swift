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

    /// State of the change being saved from the name or the phone sheet.
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
    /// `true` while the sheet to edit the phone is shown.
    var isEditingPhone = false
    /// Phone typed in the sheet. Starts as the current phone, or empty when there is none.
    var draftPhone = ""

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
        guard let newName = Self.trimmed(draftName), editState != .saving else { return false }
        return newName != viewData.participant?.name
    }

    /// Saves the typed name and closes the sheet.
    func saveName() async {
        guard canSaveName, let newName = Self.trimmed(draftName) else { return }
        if await save(.name(newName)) {
            isEditingName = false
        }
    }

    // MARK: - Phone

    /// "Editar" beside the phone: opens the sheet with the current phone.
    func startEditingPhone() {
        draftPhone = viewData.participant?.phone ?? ""
        editState = .idle
        isEditingPhone = true
    }

    /// `true` when the typed phone is not empty, differs from the current one and nothing is being saved.
    var canSavePhone: Bool {
        guard let newPhone = Self.trimmed(draftPhone), editState != .saving else { return false }
        return newPhone != viewData.participant?.phone
    }

    /// Saves the typed phone and closes the sheet.
    func savePhone() async {
        guard canSavePhone, let newPhone = Self.trimmed(draftPhone) else { return }
        if await save(.phone(newPhone)) {
            isEditingPhone = false
        }
    }

    // MARK: - Actions

    /// "Añadir" in "Protegidos". The sheet to pick a ward is not built yet.
    func startAddingWard() {}

    /// "Añadir" in "Exclusiones". The sheet to pick an exclusion is not built yet.
    func startAddingExclusion() {}

    // MARK: - Private

    /// `text` without surrounding spaces, or `nil` when it is empty.
    private static func trimmed(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Saves the change and puts the updated participant in `viewData.participant`. Returns `false` when it fails.
    private func save(_ change: EditParticipantChange) async -> Bool {
        guard let participant = viewData.participant else { return false }
        editState = .saving
        do {
            viewData.participant = try await editParticipantUseCase.execute(change, of: participant)
            editState = .idle
            return true
        } catch {
            editState = .failed(error.localizedDescription)
            return false
        }
    }
}
