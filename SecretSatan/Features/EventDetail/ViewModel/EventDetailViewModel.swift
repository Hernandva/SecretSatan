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

    /// State of the change being saved from the name sheet or the date picker.
    enum EditState: Equatable {
        case idle
        case saving
        case failed(String)
    }

    /// State of the participant being saved from the "Nuevo participante" sheet.
    enum AddParticipantState: Equatable {
        case idle
        case saving
        /// `reason` is the backend's message when it refused the participant, or `nil` for any other failure.
        case failed(reason: String?)
    }

    private(set) var state: State = .idle
    private(set) var editState: EditState = .idle
    private(set) var addParticipantState: AddParticipantState = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = EventDetailViewData()

    /// `true` while the sheet to edit the name is shown.
    var isEditingName = false
    /// Name typed in the sheet. Starts as the current name.
    var draftName = ""
    /// `true` while the date picker is shown.
    var isEditingDate = false
    /// Date chosen in the picker. Starts as the current date, or today when the event has none.
    var draftDate = Date()
    /// `true` while the "Nuevo participante" sheet is shown.
    var isAddingParticipant = false
    /// Name typed in the "Nuevo participante" sheet. Required.
    var participantName = ""
    /// Phone typed in the "Nuevo participante" sheet. Required.
    var participantPhone = ""

    private let useCase: any EventDetailUseCaseProtocol
    private let participantsUseCase: any EventParticipantsUseCaseProtocol
    private let editEventUseCase: any EditEventUseCaseProtocol
    private let newParticipantUseCase: any NewParticipantUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: EventDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.participantsUseCase = dependencies.resolveParticipantsUseCase()
        self.editEventUseCase = dependencies.resolveEditEventUseCase()
        self.newParticipantUseCase = dependencies.resolveNewParticipantUseCase()
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

    // MARK: - Name

    func startEditingName() {
        draftName = viewData.event?.name ?? ""
        editState = .idle
        isEditingName = true
    }

    /// `true` when the typed name is not empty, differs from the current one and nothing is being saved.
    var canSaveName: Bool {
        guard let newName = trimmedDraftName, editState != .saving else { return false }
        return newName != viewData.event?.name
    }

    func saveName() async {
        guard canSaveName, let newName = trimmedDraftName else { return }
        if await save(.name(newName)) {
            isEditingName = false
        }
    }

    // MARK: - Date

    func startEditingDate() {
        draftDate = viewData.event?.date ?? Date()
        editState = .idle
        isEditingDate = true
    }

    /// Saves `draftDate` when it is another day than the current date, and closes the picker.
    func saveDraftDate() async {
        if let current = viewData.event?.date, Calendar.current.isDate(current, inSameDayAs: draftDate) {
            return
        }
        guard editState != .saving else { return }
        if await save(.date(draftDate)) {
            isEditingDate = false
        }
    }

    // MARK: - New participant

    func startAddingParticipant() {
        participantName = ""
        participantPhone = ""
        addParticipantState = .idle
        isAddingParticipant = true
    }

    /// `true` when the name and the phone are filled in and nothing is being saved.
    var canSaveParticipant: Bool {
        newParticipantInput != nil && addParticipantState != .saving
    }

    /// Adds the participant, appends it to the list and closes the sheet.
    func saveParticipant() async {
        guard canSaveParticipant, let input = newParticipantInput else { return }
        addParticipantState = .saving
        do {
            viewData.participants.append(try await newParticipantUseCase.execute(input))
            addParticipantState = .idle
            isAddingParticipant = false
        } catch NewParticipantError.rejected(let reason) {
            addParticipantState = .failed(reason: reason)
        } catch {
            addParticipantState = .failed(reason: nil)
        }
    }

    // MARK: - Private

    /// The data to send, or `nil` while the name or the phone is empty.
    private var newParticipantInput: NewParticipantInput? {
        guard let name = Self.trimmed(participantName), let phone = Self.trimmed(participantPhone) else { return nil }
        return NewParticipantInput(name: name, phone: phone)
    }

    /// `text` without surrounding spaces, or `nil` when it is empty.
    private static func trimmed(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// The typed name without surrounding spaces, or `nil` when it is empty.
    private var trimmedDraftName: String? {
        Self.trimmed(draftName)
    }

    /// Saves the change and puts the updated event in `viewData.event`. Returns `false` when it fails.
    private func save(_ change: EditEventChange) async -> Bool {
        editState = .saving
        do {
            viewData.event = try await editEventUseCase.execute(change)
            editState = .idle
            return true
        } catch {
            editState = .failed(error.localizedDescription)
            return false
        }
    }
}
