import Foundation

/// Public API of the Events repository. Features depend on this protocol, never on the concrete class.
///
/// Every call needs the session saved by the Auth repository: it throws `EventsError.notSignedIn` without a valid
/// one, `NetworkError.server` when the backend rejects the request (e.g. `404` for an event of another organiser),
/// and `NetworkError` while the configuration is incomplete.
public protocol EventsRepositoryProtocol: Sendable {
    /// `GET /events`: the user's events, newest first, with their number of participants.
    func fetchEvents() async throws -> [any EventsResponseProtocol]

    /// `POST /events`: creates an event, which starts as `EventStatus.draft`, and returns it.
    @discardableResult
    func createEvent(_ request: some EventsRequestProtocol) async throws -> any EventsResponseProtocol

    /// `GET /events/:id`: the event with its participants and exclusions. Never the draw's assignments.
    func fetchEvent(id: String) async throws -> any EventDetailResponseProtocol

    /// `PATCH /events/:id`: changes the name, the date or both, and returns the updated event.
    /// Only what `request` changes is sent; the rest of the event stays as it was.
    /// Throws `EventsError.nothingToUpdate`, before any request, when `request` changes nothing.
    @discardableResult
    func updateEvent(
        id: String,
        _ request: some EventsUpdateRequestProtocol
    ) async throws -> any EventsResponseProtocol

    /// `DELETE /events/:id`: deletes the event and everything that belongs to it.
    func deleteEvent(id: String) async throws

    /// `POST /events/:id/draw`: draws the event, which becomes `EventStatus.drawn`, and returns how many assignments
    /// it created. It never returns who gives to whom.
    @discardableResult
    func drawEvent(id: String) async throws -> any EventDrawResponseProtocol
}

/// Talks to the Events services of the backend, authenticated with the session token of the Auth repository.
/// Flow: EventsRequestProtocol / EventsUpdateRequestProtocol -> EventsRequestDAO / EventsUpdateRequestDAO
/// -> /events -> EventsResponseDAO / EventDetailResponseDAO / EventDrawResponseDAO
/// -> EventsResponseProtocol / EventDetailResponseProtocol / EventDrawResponseProtocol.
public final class EventsRepository: EventsRepositoryProtocol {
    /// `events`, and `events/:id` built from it.
    static let serviceName = "events"
    /// Appended to `events/:id` to build `events/:id/draw`.
    static let drawPath = "draw"

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
        configuration: RepositoryConfiguration = EventsRepository.configuration
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

    public func fetchEvents() async throws -> [any EventsResponseProtocol] {
        let url = try configuration.url(for: Self.serviceName)
        let events: [EventsResponseDAO] = try await client.request(
            url,
            method: .get,
            headers: try await authorizationHeaders()
        )
        return events
    }

    @discardableResult
    public func createEvent(_ request: some EventsRequestProtocol) async throws -> any EventsResponseProtocol {
        let url = try configuration.url(for: Self.serviceName)
        let event: EventsResponseDAO = try await client.request(
            url,
            method: .post,
            body: EventsRequestDAO(request),
            headers: try await authorizationHeaders()
        )
        return event
    }

    public func fetchEvent(id: String) async throws -> any EventDetailResponseProtocol {
        let url = try eventURL(id: id)
        let detail: EventDetailResponseDAO = try await client.request(
            url,
            method: .get,
            headers: try await authorizationHeaders()
        )
        return detail
    }

    @discardableResult
    public func updateEvent(
        id: String,
        _ request: some EventsUpdateRequestProtocol
    ) async throws -> any EventsResponseProtocol {
        let body = EventsUpdateRequestDAO(request)
        guard !body.isEmpty else { throw EventsError.nothingToUpdate }
        let url = try eventURL(id: id)
        let event: EventsResponseDAO = try await client.request(
            url,
            method: .patch,
            body: body,
            headers: try await authorizationHeaders()
        )
        return event
    }

    public func deleteEvent(id: String) async throws {
        let url = try eventURL(id: id)
        try await client.send(url, method: .delete, headers: try await authorizationHeaders())
    }

    @discardableResult
    public func drawEvent(id: String) async throws -> any EventDrawResponseProtocol {
        let url = try eventURL(id: id).appendingPathComponent(Self.drawPath)
        let draw: EventDrawResponseDAO = try await client.request(
            url,
            method: .post,
            headers: try await authorizationHeaders()
        )
        return draw
    }
}

private extension EventsRepository {
    /// `events/:id`.
    func eventURL(id: String) throws -> URL {
        try configuration.url(for: Self.serviceName).appendingPathComponent(id)
    }

    /// `Authorization: Bearer <token>` with the saved session, which must not have expired.
    func authorizationHeaders() async throws -> [String: String] {
        guard let session = try await sessionStorage.load(), session.expiresAt > Date() else {
            throw EventsError.notSignedIn
        }
        return ["Authorization": "Bearer \(session.token)"]
    }
}
