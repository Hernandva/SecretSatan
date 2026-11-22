import Foundation

/// Display-ready data of Login. The view model owns it as a variable and adds each use case result
/// to its own field, so a new result never erases the rest of the data.
struct LoginViewData: Equatable, Sendable {
    /// `true` when the device keeps a valid session: the screen shows "Enter" instead of the sign-in buttons.
    var hasSession = false
}
