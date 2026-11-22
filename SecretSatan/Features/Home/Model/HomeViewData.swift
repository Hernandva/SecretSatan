import Foundation

/// Display-ready data of Home. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct HomeViewData: Equatable, Sendable {
    /// User of the saved session, returned by `HomeUseCase`.
    struct User: Equatable, Sendable {
        let name: String?
        let email: String?
    }

    /// User of the saved session, or `nil` until it loads or when there is no valid session.
    var user: User?
}
