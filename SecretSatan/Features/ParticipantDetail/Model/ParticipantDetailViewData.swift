import Foundation

/// Display-ready data of ParticipantDetail. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct ParticipantDetailViewData: Equatable, Sendable {
    /// The participant selected in EventDetail, returned by `ParticipantDetailUseCase`.
    struct Participant: Equatable, Sendable {
        let id: String
        let name: String
        /// Up to two letters shown on the avatar, e.g. "LM" for "Lucía Martín".
        let initials: String
    }

    /// Result of `ParticipantDetailUseCase`, or `nil` until it loads.
    var participant: Participant?
}
