import Foundation

/// Public API of the Exclusions repository. Features depend on this protocol, never on the concrete class.
///
/// Every call needs the session saved by the Auth repository: it throws `ExclusionsError.notSignedIn` without a
/// valid one, `NetworkError.server` when the backend rejects the request, and `NetworkError` while the configuration
/// is incomplete.
public protocol ExclusionsRepositoryProtocol: Sendable {
    /// `POST /events/:id/exclusions`: makes `giverId` and `receiverId` never be assigned to each other in the draw.
    /// The backend saves both directions and returns only the ones it created: two, one when the other already
    /// existed, or none when both did.
    @discardableResult
    func createExclusion(
        eventId: String,
        _ request: some ExclusionsRequestProtocol
    ) async throws -> [any ExclusionsResponseProtocol]

    /// `DELETE /events/:id/exclusions/:xid`: removes the exclusion in both directions, given the id of either one.
    func deleteExclusion(eventId: String, exclusionId: String) async throws
}

/// Talks to the exclusion services of the backend, authenticated with the session token of the Auth repository.
/// Flow: ExclusionsRequestProtocol -> ExclusionsRequestDAO -> /events/:id/exclusions
/// -> ExclusionsResponseDAO -> ExclusionsResponseProtocol.
public final class ExclusionsRepository: ExclusionsRepositoryProtocol {
    /// `events`, and `events/:id/exclusions` and `events/:id/exclusions/:xid` built from it.
    static let serviceName = "events"
    /// Path segment after the event id.
    static let exclusionsPath = "exclusions"

    /// Services of the backend, on the base URL of the app's Info.plist (`API_BASE_URL` in Config.xcconfig).
    public static let configuration = RepositoryConfiguration(
        baseURL: RepositoryConfiguration.appBaseURL,
        serviceNames: [serviceName]
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration
    private let sessionStorage: any AuthSessionStorageProtocol

    /// Reads the session token from the Keychain storage of the Auth repository.
    public convenience init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = ExclusionsRepository.configuration
    ) {
        self.init(client: client, configuration: configuration, sessionStorage: AuthSessionStorage())
    }

    /// Lets tests inject their own session storage.
    init(
        client: NetworkClient,
        configuration: RepositoryConfiguration,
        sessionStorage: any AuthSessionStorageProtocol
    ) {
        self.client = client
        self.configuration = configuration
        self.sessionStorage = sessionStorage
    }

    @discardableResult
    public func createExclusion(
        eventId: String,
        _ request: some ExclusionsRequestProtocol
    ) async throws -> [any ExclusionsResponseProtocol] {
        let exclusions: [ExclusionsResponseDAO] = try await client.request(
            try exclusionsURL(eventId: eventId),
            method: .post,
            body: ExclusionsRequestDAO(request),
            headers: try await authorizationHeaders()
        )
        return exclusions
    }

    public func deleteExclusion(eventId: String, exclusionId: String) async throws {
        let url = try exclusionsURL(eventId: eventId).appendingPathComponent(exclusionId)
        try await client.send(url, method: .delete, headers: try await authorizationHeaders())
    }
}

private extension ExclusionsRepository {
    /// `events/:id/exclusions`.
    func exclusionsURL(eventId: String) throws -> URL {
        try configuration.url(for: Self.serviceName)
            .appendingPathComponent(eventId)
            .appendingPathComponent(Self.exclusionsPath)
    }

    /// `Authorization: Bearer <token>` with the saved session, which must not have expired.
    func authorizationHeaders() async throws -> [String: String] {
        guard let session = try await sessionStorage.load(), session.expiresAt > Date() else {
            throw ExclusionsError.notSignedIn
        }
        return ["Authorization": "Bearer \(session.token)"]
    }
}
