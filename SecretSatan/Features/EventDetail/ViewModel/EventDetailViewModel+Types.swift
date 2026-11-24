import Foundation

// MARK: - Types

/// States and sheets of `EventDetailViewModel`, kept apart so the view model holds only its logic.
extension EventDetailViewModel {
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
        /// Edits the message of the event.
        case editMessage
        /// "Nuevo participante": adds a participant.
        case newParticipant
        /// Phone contacts of the device, to pick several and add them as participants.
        case contacts

        var id: Self { self }
    }

    /// State of the change being saved from the name, date or message sheet.
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
}
