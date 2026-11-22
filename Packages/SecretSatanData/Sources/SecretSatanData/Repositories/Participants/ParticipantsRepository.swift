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

    /// `GET /events/:id/participants/:pid/wards`: the participants whose `guardianId` is `participantId`,
    /// e.g. the children whose link this participant receives. Empty when it is nobody's guardian.
    func fetchWards(eventId: String, participantId: String) async throws -> [any ParticipantsResponseProtocol]

    /// `GET /events/:id/participants/:pid/excluded`: the participants `participantId` must not be assigned in the
    /// draw, the `receiverId` of every exclusion whose `giverId` is `participantId`. Empty when it has none.
    func fetchExcluded(eventId: String, participantId: String) async throws -> [any ParticipantsResponseProtocol]

    /// `POST /events/:id/participants/:pid/link`: a new link for the participant, e.g. to send it again to someone
    /// who lost it, with the message and who to deliver it to.
    func fetchLink(eventId: String, participantId: String) async throws -> any ParticipantLinkResponseProtocol
}

/// Talks to the participant services of the backend, authenticated with the session token of the Auth repository.
/// Flow: ParticipantsRequestProtocol -> ParticipantsRequestDAO -> /events/:id/participants
/// -> ParticipantsResponseDAO / ParticipantLinkResponseDAO
/// -> ParticipantsResponseProtocol / ParticipantLinkResponseProtocol.
public final class ParticipantsRepository: ParticipantsRepositoryProtocol {
    /// `events`, and `events/:id/participants` and `events/:id/participants/:pid` built from it.
    static let serviceName = "events"
    /// Path segment after the event id.
    static let participantsPath = "participants"
    /// Path segment after the participant id that lists its wards.
    static let wardsPath = "wards"
    /// Path segment after the participant id that lists the participants it must not be assigned.
    static let excludedPath = "excluded"
    /// Path segment after the participant id that creates its link.
    static let linkPath = "link"

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

    public func fetchWards(
        eventId: String,
        participantId: String
    ) async throws -> [any ParticipantsResponseProtocol] {
        try await fetchParticipants(eventId: eventId, participantId: participantId, path: Self.wardsPath)
    }

    public func fetchExcluded(
        eventId: String,
        participantId: String
    ) async throws -> [any ParticipantsResponseProtocol] {
        try await fetchParticipants(eventId: eventId, participantId: participantId, path: Self.excludedPath)
    }

    public func fetchLink(
        eventId: String,
        participantId: String
    ) async throws -> any ParticipantLinkResponseProtocol {
        let url = try participantsURL(eventId: eventId)
            .appendingPathComponent(participantId)
            .appendingPathComponent(Self.linkPath)
        let link: ParticipantLinkResponseDAO = try await client.request(
            url,
            method: .post,
            headers: try await authorizationHeaders()
        )
        return link
    }

    /// `GET events/:id/participants/:pid/<path>`, which answers with a list of participants.
    private func fetchParticipants(
        eventId: String,
        participantId: String,
        path: String
    ) async throws -> [any ParticipantsResponseProtocol] {
        let url = try participantsURL(eventId: eventId)
            .appendingPathComponent(participantId)
            .appendingPathComponent(path)
        let participants: [ParticipantsResponseDAO] = try await client.request(
            url,
            method: .get,
            headers: try await authorizationHeaders()
        )
        return participants
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
