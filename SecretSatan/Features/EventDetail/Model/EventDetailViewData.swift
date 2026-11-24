import Foundation

/// Display-ready data of EventDetail. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct EventDetailViewData: Equatable, Sendable {
    /// The event selected in Home, returned by `EventDetailUseCase`.
    struct Event: Equatable, Sendable {
        let id: String
        let name: String
        /// Day of the event, or `nil` when it has none.
        let date: Date?
        /// Message of the organiser for the participants, or `nil` when it has none.
        let message: String?
        let participantCount: Int
        /// `true` once the draw has been made.
        let isDrawn: Bool
    }

    /// One row of the participant list, returned by `EventParticipantsUseCase`.
    struct Participant: Hashable, Sendable, Identifiable {
        let id: String
        let name: String
        /// `nil` for participants without a phone, such as children.
        let phone: String?
        /// Participant who receives this participant's link, e.g. the guardian of a child, or `nil`.
        let guardianId: String?
        /// Up to two letters shown on the avatar, e.g. "LM" for "Lucía Martín".
        let initials: String

        /// Builds the initials from the first letter of the first two words of `name`:
        /// "Lucía Martín" -> "LM", "Pablo" -> "P".
        init(id: String, name: String, phone: String? = nil, guardianId: String? = nil) {
            self.id = id
            self.name = name
            self.phone = phone
            self.guardianId = guardianId
            self.initials = name.initials
        }
    }

    /// One row of the phone contacts sheet, returned by `PhoneContactsUseCase`.
    struct Contact: Hashable, Sendable, Identifiable {
        let id: String
        let name: String
        /// First phone of the contact, the one the participant gets.
        let phone: String
        /// Up to two letters shown on the avatar, e.g. "LM" for "Lucía Martín".
        let initials: String

        init(id: String, name: String, phone: String) {
            self.id = id
            self.name = name
            self.phone = phone
            self.initials = name.initials
        }
    }

    /// Result of the draw made on this screen, returned by `DrawEventUseCase`.
    struct Draw: Equatable, Sendable {
        /// Number of assignments the draw created. Who gives to whom is never shown.
        let assignments: Int
    }

    /// Result of `EventDetailUseCase`, or `nil` until it loads.
    var event: Event?
    /// Participants of the event, returned by `EventParticipantsUseCase`.
    var participants: [Participant] = []
    /// Result of `DrawEventUseCase`, or `nil` until the draw is made on this screen.
    var draw: Draw?
    /// Phone contacts of the device, returned by `PhoneContactsUseCase`. Empty until the contacts sheet loads them.
    var contacts: [Contact] = []
}

extension EventDetailViewData {
    /// Contacts that are not participants yet (compared by the digits of the phone) and whose name or phone contains
    /// `query`, ignoring case and accents. An empty `query` keeps them all.
    func contacts(matching query: String) -> [Contact] {
        let participantPhones = Set(participants.compactMap { $0.phone.map(Self.digits(of:)) })
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return contacts.filter { contact in
            guard !participantPhones.contains(Self.digits(of: contact.phone)) else { return false }
            guard !query.isEmpty else { return true }
            return contact.name.localizedStandardContains(query) || contact.phone.localizedStandardContains(query)
        }
    }

    /// Only the digits of `phone`, so "+34 600-000 001" and "34600000001" match.
    private static func digits(of phone: String) -> String {
        phone.filter(\.isNumber)
    }
}
