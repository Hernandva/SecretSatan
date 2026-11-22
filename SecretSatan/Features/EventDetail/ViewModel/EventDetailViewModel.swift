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

    private(set) var state: State = .idle
    private(set) var editState: EditState = .idle
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

    private let useCase: any EventDetailUseCaseProtocol
    private let participantsUseCase: any EventParticipantsUseCaseProtocol
    private let editEventUseCase: any EditEventUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: EventDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.participantsUseCase = dependencies.resolveParticipantsUseCase()
        self.editEventUseCase = dependencies.resolveEditEventUseCase()
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

    // MARK: - Private

    /// The typed name without surrounding spaces, or `nil` when it is empty.
    private var trimmedDraftName: String? {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
