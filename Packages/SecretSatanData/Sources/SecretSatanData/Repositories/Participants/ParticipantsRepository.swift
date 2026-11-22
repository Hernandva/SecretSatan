import Foundation

/// Public API of the Participants repository. Features depend on this protocol, never on the concrete class.
///
/// Every call needs the session saved by the Auth repository: it throws `ParticipantsError.notSignedIn` without a
/// valid one, `NetworkError.server` when the backend rejects the request, and `NetworkError` while the configuration
/// is incomplete. The backend answers, among others:
/// - `400` when the name is missing, there is neither a phone nor a guardian, or the guardian is not valid
///   (another event, no phone, or the participant itself).
/// - `404` when the participant does not exist or belongs to another event.
/// - `409` when adding or removing after the draw.
public protocol ParticipantsRepositoryProtocol: Sendable {
    /// `POST /events/:id/participants`: adds a participant and returns it. Only before the draw.
    @discardableResult
    func addParticipant(
        eventId: String,
        _ request: some ParticipantsRequestProtocol
    ) async throws -> any ParticipantsResponseProtocol

    /// `PUT /events/:id/participants/:pid`: replaces every field of the participant and returns it.
    /// A field left `nil` is cleared, and so is the participant's `family`, which this repository never sends.
    /// Allowed after the draw too, e.g. to fix a phone.
    @discardableResult
    func updateParticipant(
        eventId: String,
        participantId: String,
        _ request: some ParticipantsRequestProtocol
    ) async throws -> any ParticipantsResponseProtocol

    /// `DELETE /events/:id/participants/:pid`: removes the participant and its exclusions. Only before the draw.
    func deleteParticipant(eventId: String, participantId: String) async throws
}

/// Talks to the participant services of the backend, authenticated with the session token of the Auth repository.
/// Flow: ParticipantsRequestProtocol -> ParticipantsRequestDAO -> /events/:id/participants
/// -> ParticipantsResponseDAO -> ParticipantsResponseProtocol.
public final class ParticipantsRepository: ParticipantsRepositoryProtocol {
    /// `events`, and `events/:id/participants` and `events/:id/participants/:pid` built from it.
    static let serviceName = "events"
    /// Path segment after the event id.
    static let participantsPath = "participants"

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
        configuration: RepositoryConfiguration = ParticipantsRepository.configuration
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
    public func addParticipant(
        eventId: String,
        _ request: some ParticipantsRequestProtocol
    ) async throws -> any ParticipantsResponseProtocol {
        let url = try participantsURL(eventId: eventId)
        let participant: ParticipantsResponseDAO = try await client.request(
            url,
            method: .post,
            body: ParticipantsRequestDAO(request, sendsEmptyFields: false),
            headers: try await authorizationHeaders()
        )
        return participant
    }

    @discardableResult
    public func updateParticipant(
        eventId: String,
        participantId: String,
        _ request: some ParticipantsRequestProtocol
    ) async throws -> any ParticipantsResponseProtocol {
        let url = try participantsURL(eventId: eventId).appendingPathComponent(participantId)
        let participant: ParticipantsResponseDAO = try await client.request(
            url,
            method: .put,
            body: ParticipantsRequestDAO(request, sendsEmptyFields: true),
            headers: try await authorizationHeaders()
        )
        return participant
    }

    public func deleteParticipant(eventId: String, participantId: String) async throws {
        let url = try participantsURL(eventId: eventId).appendingPathComponent(participantId)
        try await client.send(url, method: .delete, headers: try await authorizationHeaders())
    }

    /// `events/:id/participants`.
    private func participantsURL(eventId: String) throws -> URL {
        try configuration.url(for: Self.serviceName)
            .appendingPathComponent(eventId)
            .appendingPathComponent(Self.participantsPath)
    }

    /// `Authorization: Bearer <token>` with the saved session, which must not have expired.
    private func authorizationHeaders() async throws -> [String: String] {
        guard let session = try await sessionStorage.load(), session.expiresAt > Date() else {
            throw ParticipantsError.notSignedIn
        }
        return ["Authorization": "Bearer \(session.token)"]
    }
}
