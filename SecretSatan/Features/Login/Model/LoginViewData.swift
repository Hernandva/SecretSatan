import Foundation

/// Display-ready data of Login. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct LoginViewData: Equatable, Sendable {
    /// User signed in by `LoginUseCase`.
    struct Session: Equatable, Sendable {
        /// Identifier of the user in the SecretSatan backend.
        let userID: String
        let name: String?
        let email: String?
    }

    /// Result of `LoginUseCase`, or `nil` until the user signs in.
    var session: Session?
}
