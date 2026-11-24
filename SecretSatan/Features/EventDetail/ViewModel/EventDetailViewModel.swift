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

    /// Bottom sheets of EventDetail. The screen shows at most one at a time.
    enum Sheet: Identifiable {
        /// Edits the name of the event.
        case editName
        /// Picks the date of the event.
        case editDate
        /// "Nuevo participante": adds a participant.
        case newParticipant
        /// Phone contacts of the device, to pick several and add them as participants.
        case contacts

        var id: Self { self }
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

    /// State of the phone contacts shown in the contacts sheet.
    enum ContactsState: Equatable {
        case idle
        case loading
        case loaded
        /// The user has not allowed access to the contacts.
        case denied
        case failed
    }

    /// State of the draw started with "Sortear".
    enum DrawState: Equatable {
        case idle
        case drawing
    }

    /// Fewest participants an event needs before it can be drawn.
    static let minimumParticipantsToDraw = 3

    private(set) var state: State = .idle
    private(set) var editState: EditState = .idle
    private(set) var addParticipantState: AddParticipantState = .idle
    private(set) var drawState: DrawState = .idle
    private(set) var contactsState: ContactsState = .idle
    /// State of the contacts being added from the contacts sheet.
    private(set) var addContactsState: AddParticipantState = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = EventDetailViewData()

    /// Sheet shown on top of the screen, or `nil`. A single value, so two sheets are never shown at once.
    var sheet: Sheet?

    /// Name typed in the sheet. Starts as the current name.
    var draftName = ""
    /// Date chosen in the picker. Starts as the current date, or today when the event has none.
    var draftDate = Date()
    /// Name typed in the "Nuevo participante" sheet. Required.
    var participantName = ""
    /// Phone typed in the "Nuevo participante" sheet. Required.
    var participantPhone = ""
    /// Text typed in the search bar of the contacts sheet.
    var contactsQuery = ""
    /// Contacts picked in the contacts sheet, added as participants with "Añadir".
    private(set) var selectedContactIds: Set<String> = []
    /// `true` after removing a participant fails, so the view shows an alert. The view sets it back to `false`.
    var deleteFailed = false
    /// The backend's message when it refused to remove the participant, or `nil` for any other failure.
    private(set) var deleteFailureReason: String?
    /// `true` while the view asks to confirm the draw, which can't be undone. The view sets it back to `false`.
    var drawConfirmationShown = false
    /// `true` after the draw fails, so the view shows an alert. The view sets it back to `false`.
    var drawFailed = false
    /// The backend's message when it refused the draw, or `nil` for any other failure.
    private(set) var drawFailureReason: String?

    private let useCase: any EventDetailUseCaseProtocol
    private let participantsUseCase: any EventParticipantsUseCaseProtocol
    private let editEventUseCase: any EditEventUseCaseProtocol
    private let newParticipantUseCase: any NewParticipantUseCaseProtocol
    private let deleteParticipantUseCase: any DeleteParticipantUseCaseProtocol
    private let drawEventUseCase: any DrawEventUseCaseProtocol
    private let phoneContactsUseCase: any PhoneContactsUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: EventDetailDependencies) {
        self.useCase = dependencies.resolveUseCase()
        self.participantsUseCase = dependencies.resolveParticipantsUseCase()
        self.editEventUseCase = dependencies.resolveEditEventUseCase()
        self.newParticipantUseCase = dependencies.resolveNewParticipantUseCase()
        self.deleteParticipantUseCase = dependencies.resolveDeleteParticipantUseCase()
        self.drawEventUseCase = dependencies.resolveDrawEventUseCase()
        self.phoneContactsUseCase = dependencies.resolvePhoneContactsUseCase()
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
        guard sheet == nil else { return }
        draftName = viewData.event?.name ?? ""
        editState = .idle
        sheet = .editName
    }

    /// `true` when the typed name is not empty, differs from the current one and nothing is being saved.
    var canSaveName: Bool {
        guard let newName = trimmedDraftName, editState != .saving else { return false }
        return newName != viewData.event?.name
    }

    func saveName() async {
        guard canSaveName, let newName = trimmedDraftName else { return }
        if await save(.name(newName)) {
            sheet = nil
        }
    }

    // MARK: - Date

    func startEditingDate() {
        guard sheet == nil else { return }
        draftDate = viewData.event?.date ?? Date()
        editState = .idle
        sheet = .editDate
    }

    /// `true` when the picked day differs from the current date (or the event has none) and nothing is being saved.
    var canSaveDate: Bool {
        guard editState != .saving else { return false }
        guard let current = viewData.event?.date else { return true }
        return !Calendar.current.isDate(current, inSameDayAs: draftDate)
    }

    /// Saves the picked day and closes the sheet.
    func saveDate() async {
        guard canSaveDate else { return }
        if await save(.date(draftDate)) {
            sheet = nil
        }
    }

    // MARK: - New participant

    /// `true` until the event is drawn: after the draw, participants can't be added or removed.
    var canChangeParticipants: Bool {
        !isDrawn
    }

    /// "Añadir": opens the contacts sheet. "Añadir otros" in it opens the "Nuevo participante" sheet.
    func startAddingParticipant() {
        guard sheet == nil, canChangeParticipants else { return }
        contactsQuery = ""
        selectedContactIds = []
        addContactsState = .idle
        sheet = .contacts
    }

    /// "Añadir otros": closes the contacts sheet and opens the "Nuevo participante" sheet, to type someone who is not
    /// in the contacts.
    func startAddingOtherParticipant() {
        guard sheet == .contacts, canChangeParticipants, addContactsState != .saving else { return }
        participantName = ""
        participantPhone = ""
        addParticipantState = .idle
        sheet = .newParticipant
    }

    /// `true` when the name and the phone are filled in and nothing is being saved.
    var canSaveParticipant: Bool {
        canChangeParticipants && newParticipantInput != nil && addParticipantState != .saving
    }

    /// Adds the participant, appends it to the list and closes the sheet.
    func saveParticipant() async {
        guard canSaveParticipant, let input = newParticipantInput else { return }
        addParticipantState = .saving
        do {
            viewData.participants.append(try await newParticipantUseCase.execute(input))
            addParticipantState = .idle
            sheet = nil
        } catch {
            addParticipantState = .failed(reason: Self.rejectionReason(of: error))
        }
    }

    // MARK: - Contacts

    /// Contacts the sheet lists: those that are not participants yet and match the search bar.
    var visibleContacts: [EventDetailViewData.Contact] {
        viewData.contacts(matching: contactsQuery)
    }

    /// Loads the phone contacts the first time the contacts sheet opens. Asks for access to them if needed.
    func loadContacts() async {
        guard contactsState != .loading, contactsState != .loaded else { return }
        contactsState = .loading
        do {
            viewData.contacts = try await phoneContactsUseCase.execute()
            contactsState = .loaded
        } catch PhoneContactsError.accessDenied {
            contactsState = .denied
        } catch {
            contactsState = .failed
        }
    }

    /// Picks the contact, or unpicks it when it was picked.
    func toggleContact(_ contact: EventDetailViewData.Contact) {
        guard addContactsState != .saving else { return }
        if selectedContactIds.remove(contact.id) == nil {
            selectedContactIds.insert(contact.id)
        }
    }

    /// `true` when at least one contact is picked and nothing is being saved.
    var canAddContacts: Bool {
        canChangeParticipants && !selectedContactIds.isEmpty && addContactsState != .saving
    }

    /// Adds the picked contacts one by one, appends each to the list and closes the sheet. If one fails, it stops:
    /// the ones added leave the selection and the rest stay picked to try again.
    func addSelectedContacts() async {
        guard canAddContacts else { return }
        addContactsState = .saving
        let picked = viewData.contacts.filter { selectedContactIds.contains($0.id) }
        for contact in picked {
            do {
                let input = NewParticipantInput(name: contact.name, phone: contact.phone)
                viewData.participants.append(try await newParticipantUseCase.execute(input))
                selectedContactIds.remove(contact.id)
            } catch {
                addContactsState = .failed(reason: Self.rejectionReason(of: error))
                return
            }
        }
        addContactsState = .idle
        sheet = nil
    }

    // MARK: - Delete participant

    /// Removes the participant from the list at once and from the event on the backend. If that fails, the
    /// participant goes back to its place and `deleteFailed` turns on. Does nothing once the event is drawn.
    func deleteParticipant(_ participant: EventDetailViewData.Participant) async {
        guard canChangeParticipants, let index = viewData.participants.firstIndex(of: participant) else { return }
        viewData.participants.remove(at: index)
        do {
            try await deleteParticipantUseCase.execute(id: participant.id)
        } catch {
            viewData.participants.insert(participant, at: min(index, viewData.participants.count))
            if case DeleteParticipantError.rejected(let reason) = error {
                deleteFailureReason = reason
            } else {
                deleteFailureReason = nil
            }
            deleteFailed = true
        }
    }

    // MARK: - Draw

    /// `true` when the event came from Home already drawn or it has just been drawn here.
    var isDrawn: Bool {
        viewData.event?.isDrawn == true || viewData.draw != nil
    }

    /// `true` when the event has at least `minimumParticipantsToDraw` participants.
    var hasEnoughParticipantsToDraw: Bool {
        viewData.participants.count >= Self.minimumParticipantsToDraw
    }

    /// `true` when the event is not drawn yet, has enough participants and no draw is running.
    var canDraw: Bool {
        !isDrawn && hasEnoughParticipantsToDraw && drawState != .drawing
    }

    /// "Sortear": asks to confirm the draw before making it.
    func startDrawing() {
        guard canDraw else { return }
        drawConfirmationShown = true
    }

    /// Draws the event, once confirmed, and keeps the result in `viewData.draw`. If it fails, `drawFailed` turns on.
    func draw() async {
        guard canDraw else { return }
        drawState = .drawing
        do {
            viewData.draw = try await drawEventUseCase.execute()
        } catch {
            if case DrawEventError.rejected(let reason) = error {
                drawFailureReason = reason
            } else {
                drawFailureReason = nil
            }
            drawFailed = true
        }
        drawState = .idle
    }

    // MARK: - Private

    /// The data to send, or `nil` while the name or the phone is empty.
    private var newParticipantInput: NewParticipantInput? {
        guard let name = Self.trimmed(participantName), let phone = Self.trimmed(participantPhone) else { return nil }
        return NewParticipantInput(name: name, phone: phone)
    }

    /// The typed name without surrounding spaces, or `nil` when it is empty.
    private var trimmedDraftName: String? {
        Self.trimmed(draftName)
    }
}

private extension EventDetailViewModel {
    /// The backend's message when it refused a new participant, or `nil` for any other failure.
    static func rejectionReason(of error: any Error) -> String? {
        guard case NewParticipantError.rejected(let reason) = error else { return nil }
        return reason
    }

    /// `text` without surrounding spaces, or `nil` when it is empty.
    static func trimmed(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Saves the change and puts the updated event in `viewData.event`. Returns `false` when it fails.
    func save(_ change: EditEventChange) async -> Bool {
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
