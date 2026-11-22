import Foundation

/// Display-ready data of ParticipantDetail. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct ParticipantDetailViewData: Equatable, Sendable {
    /// Another participant of the event, shown as a row with its avatar.
    struct Member: Equatable, Sendable, Identifiable {
        let id: String
        let name: String
        /// Up to two letters shown on the avatar, e.g. "MG" for "Marcos García".
        let initials: String

        /// Builds the initials from `name`: "Marcos García" -> "MG".
        init(id: String, name: String) {
            self.id = id
            self.name = name
            self.initials = name.initials
        }
    }

    /// The participant selected in EventDetail, returned by `ParticipantDetailUseCase`.
    struct Participant: Equatable, Sendable {
        let id: String
        let name: String
        /// Up to two letters shown on the avatar, e.g. "LM" for "Lucía Martín".
        let initials: String
        /// `nil` for participants without a phone, such as children.
        let phone: String?
        /// Participant who receives this participant's link, e.g. the guardian of a child, or `nil`.
        /// Sent back unchanged when the participant is edited, because the edit replaces every field.
        let guardianId: String?

        /// `true` for a ward, such as a child: its guardian receives its link, so it has no phone of its own
        /// and can't be anybody's guardian. The screen hides "Teléfono" and "Protegidos" for it.
        var hasGuardian: Bool {
            guardianId != nil
        }
    }

    /// Result of `ParticipantDetailUseCase`, or `nil` until it loads.
    var participant: Participant?
    /// "Protegidos": participants whose link this participant receives, e.g. their children.
    /// Returned by `ParticipantWardsUseCase`.
    var wards: [Member] = []
    /// "Exclusiones": participants this participant must not be assigned in the draw.
    /// Returned by `ParticipantExclusionsUseCase`.
    var exclusions: [Member] = []
    /// Participants offered in the "Nueva exclusión" sheet. Returned by `ExclusionCandidatesUseCase`.
    var exclusionCandidates: [Member] = []
}
