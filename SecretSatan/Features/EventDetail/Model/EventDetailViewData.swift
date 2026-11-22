import Foundation

/// Display-ready data of EventDetail. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct EventDetailViewData: Equatable, Sendable {
    /// The event shown on the screen, returned by `EventDetailUseCase`.
    struct Event: Equatable, Sendable {
        let id: String
        let name: String
        /// Day of the event, or `nil` when it has none.
        let date: Date?
        let participantCount: Int
    }

    /// Result of `EventDetailUseCase`, or `nil` until it loads.
    var event: Event?
}
