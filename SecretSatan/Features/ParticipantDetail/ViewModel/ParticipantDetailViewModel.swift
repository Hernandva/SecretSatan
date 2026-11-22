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

    /// Bottom sheets of ParticipantDetail. The screen shows at most one at a time.
    enum Sheet: Identifiable {
        /// Edits the name of the participant.
        case editName
        /// Edits the phone of the participant.
        case editPhone
        /// "Nuevo protegido": adds a ward of the participant.
        case newWard

        var id: Self { self }
    }

    /// State of the change being saved from the name or the phone sheet.
    enum EditState: Equatable {
        case idle
        case saving
        case failed(String)
    }

    /// State of the ward being saved from the "Nuevo protegido" sheet.
    enum AddWardState: Equatable {
        case idle
        case saving
        /// `reason` is the backend's message when it refused the ward, or `nil` for any other failure.
        case failed(reason: String?)
    }

    private(set) var state: State = .idle
    private(set) var editState: EditState = .idle
    private(set) var addWardState: AddWardState = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = ParticipantDetailViewData()

    /// Sheet shown on top of the screen, or `nil`. A single value, so two sheets are never shown at once.
    var sheet: Sheet?

    /// Name typed in the sheet. Starts as the current name.
    var draftName = ""
    /// Phone typed in the sheet. Starts as the current phone, or empty when there is none.
    var draftPhone = ""
    /// Name typed in the "Nuevo protegido" sheet. Required.
    var wardName = ""

    private let useCase: any ParticipantDetailUseCaseProtocol
    private let wardsUseCase: any ParticipantWardsUseCaseProtocol
    private let exclusionsUseCase: any ParticipantExclusionsUseCaseProtocol
    private let editParticipantUseCase: any EditParticipantUseCaseProtocol
    private let addWardUseCase: any AddWardUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: ParticipantDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.wardsUseCase = dependencies.resolveWardsUseCase()
        self.exclusionsUseCase = dependencies.resolveExclusionsUseCase()
        self.editParticipantUseCase = dependencies.resolveEditParticipantUseCase()
        self.addWardUseCase = dependencies.resolveAddWardUseCase()
    }

    /// Shows the participant passed in by EventDetail, then loads its exclusions and, unless it has a guardian,
    /// its wards at the same time.
    func load() async {
        state = .loading
        do {
            let participant = try await useCase.execute()
            viewData.participant = participant
            async let exclusions = exclusionsUseCase.execute()
            // A participant with a guardian can't have wards, so their list is not requested.
            if !participant.hasGuardian {
                viewData.wards = try await wardsUseCase.execute()
            }
            viewData.exclusions = try await exclusions
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Name

    /// "Editar" beside the name: opens the sheet with the current name.
    func startEditingName() {
        guard sheet == nil else { return }
        draftName = viewData.participant?.name ?? ""
        editState = .idle
        sheet = .editName
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
            sheet = nil
        }
    }

    // MARK: - Phone

    /// "Editar" beside the phone: opens the sheet with the current phone.
    func startEditingPhone() {
        guard sheet == nil else { return }
        draftPhone = viewData.participant?.phone ?? ""
        editState = .idle
        sheet = .editPhone
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
            sheet = nil
        }
    }

    // MARK: - New ward

    /// "Añadir" in "Protegidos": opens the "Nuevo protegido" sheet with an empty name.
    func startAddingWard() {
        guard sheet == nil else { return }
        wardName = ""
        addWardState = .idle
        sheet = .newWard
    }

    /// `true` when the name is filled in and nothing is being saved.
    var canSaveWard: Bool {
        Self.trimmed(wardName) != nil && addWardState != .saving
    }

    /// Adds the ward, appends it to "Protegidos" and closes the sheet.
    func saveWard() async {
        guard canSaveWard, let name = Self.trimmed(wardName) else { return }
        addWardState = .saving
        do {
            viewData.wards.append(try await addWardUseCase.execute(name: name))
            addWardState = .idle
            sheet = nil
        } catch AddWardError.rejected(let reason) {
            addWardState = .failed(reason: reason)
        } catch {
            addWardState = .failed(reason: nil)
        }
    }

    // MARK: - Actions

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
