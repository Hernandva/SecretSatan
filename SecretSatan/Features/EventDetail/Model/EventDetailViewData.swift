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
    }

    /// One row of the participant list, returned by `EventParticipantsUseCase`.
    struct Participant: Equatable, Sendable, Identifiable {
        let id: String
        let name: String
        /// Up to two letters shown on the avatar, e.g. "LM" for "Lucía Martín".
        let initials: String

        /// Builds the initials from the first letter of the first two words of `name`:
        /// "Lucía Martín" -> "LM", "Pablo" -> "P".
        init(id: String, name: String) {
            self.id = id
            self.name = name
            self.initials = name.split(separator: " ")
                .prefix(2)
                .compactMap(\.first)
                .map { String($0).uppercased() }
                .joined()
        }
    }

    /// Result of `EventDetailUseCase`, or `nil` until it loads.
    var event: Event?
    /// Participants of the event, returned by `EventParticipantsUseCase`.
    var participants: [Participant] = []
}
