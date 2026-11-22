import Foundation

/// Display-ready data of Home. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct HomeViewData: Equatable, Sendable {
    /// User of the saved session, returned by `HomeUseCase`.
    struct User: Equatable, Sendable {
        let name: String?
        let email: String?
    }

    /// One row of the event list, returned by `EventsUseCase`.
    struct Event: Equatable, Sendable, Identifiable {
        let id: String
        let name: String
        let participantCount: Int
    }

    /// User of the saved session, or `nil` until it loads or when there is no valid session.
    var user: User?
    /// Events of the user, newest first, returned by `EventsUseCase`.
    var events: [Event] = []
}
