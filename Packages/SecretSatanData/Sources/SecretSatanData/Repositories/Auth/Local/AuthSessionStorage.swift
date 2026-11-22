import Foundation

/// On-device storage of the Auth session: one value in the Keychain under `AuthSessionStorage.key`.
protocol AuthSessionStorageProtocol: Sendable {
    /// The stored session, or `nil` when the user has not signed in yet.
    func load() async throws -> AuthResponseDAO?
    /// Saves the session, replacing the previous one.
    func save(_ session: AuthResponseDAO) async throws
    /// Removes the stored session.
    func remove() async throws
}

/// Writes the session as JSON through a `LocalStore`, the Keychain by default because it holds the session token.
struct AuthSessionStorage: AuthSessionStorageProtocol {
    /// Do not change it once the app ships: the session saved under the old key would be lost.
    static let key = "secretSatanData.auth"

    private let store: any LocalStore

    init(store: any LocalStore = KeychainStore()) {
        self.store = store
    }

    func load() async throws -> AuthResponseDAO? {
        guard let data = try await store.read(key: Self.key) else { return nil }
        return try JSONDecoder().decode(AuthResponseDAO.self, from: data)
    }

    func save(_ session: AuthResponseDAO) async throws {
        try await store.write(JSONEncoder().encode(session), key: Self.key)
    }

    func remove() async throws {
        try await store.remove(key: Self.key)
    }
}
