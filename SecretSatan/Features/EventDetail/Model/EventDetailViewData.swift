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
}
