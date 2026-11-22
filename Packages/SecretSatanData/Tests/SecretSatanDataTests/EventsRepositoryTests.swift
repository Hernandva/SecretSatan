import Alamofire
import Foundation
@testable import SecretSatanData
import Testing

@Suite(.serialized)
struct EventsRepositoryTests {
    private struct CreateRequest: EventsRequestProtocol {
        let name: String
        var date: Date?
        var budget: Decimal?
    }

    private static let backend = RepositoryConfiguration(
        baseURL: "https://backend.test",
        serviceNames: EventsRepository.configuration.serviceNames
    )

    private static let validSession = AuthResponseDAO(
        token: "session-token",
        expiresAt: Date().addingTimeInterval(3_600),
        userDAO: AuthUserDAO(id: "user-1", name: nil, email: nil)
    )

    private static func repository(
        configuration: RepositoryConfiguration = backend,
        session: AuthResponseDAO? = validSession
    ) -> EventsRepository {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [EventsStubURLProtocol.self]
        let client = NetworkClient(session: Session(configuration: sessionConfiguration))
        return EventsRepository(
            client: client,
            configuration: configuration,
            sessionStorage: EventsSessionStorage(session: session)
        )
    }

    private static func stub(status: Int, body: String) {
        EventsStubURLProtocol.statusCode = status
        EventsStubURLProtocol.responseBody = Data(body.utf8)
    }

    @Test func declaresTheEventsService() {
        #expect(EventsRepository.configuration.serviceNames == ["events"])
    }

    @Test func listsTheEventsWithTheSessionToken() async throws {
        Self.stub(status: 200, body: """
        [{"id":"E1","name":"Navidad familia 2026","date":"2026-12-24T20:00:00Z","budget":30,
          "status":"drawn","participantCount":8},
         {"id":"E2","name":"Amigo invisible oficina","date":null,"budget":null,
          "status":"draft","participantCount":0}]
        """)

        let events = try await Self.repository().fetchEvents()

        let sent = try #require(EventsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "GET")
        #expect(sent.url?.absoluteString == "https://backend.test/events")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer session-token")
        #expect(events.map(\.id) == ["E1", "E2"])
        #expect(events[0].date == Date(timeIntervalSince1970: 1_798_142_400))
        #expect(events[0].budget == 30)
        #expect(events[0].status == .drawn)
        #expect(events[0].participantCount == 8)
        #expect(events[1].date == nil)
        #expect(events[1].budget == nil)
        #expect(events[1].status == .draft)
    }

    @Test func createsAnEventWithOnlyTheFieldsItHas() async throws {
        Self.stub(status: 200, body: """
        {"id":"E1","name":"Navidad","date":null,"budget":null,"status":"draft","participantCount":0}
        """)

        let event = try await Self.repository().createEvent(CreateRequest(name: "Navidad", budget: 30))

        let sent = try #require(EventsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "https://backend.test/events")
        let body = try JSONSerialization.jsonObject(
            with: try #require(EventsStubURLProtocol.lastBody)
        ) as? [String: Any]
        #expect(body?["name"] as? String == "Navidad")
        #expect(body?["budget"] as? Int == 30)
        #expect(body?.keys.contains("date") == false)
        #expect(event.status == .draft)
    }

    @Test func sendsTheDateAsISO8601() async throws {
        Self.stub(status: 200, body: """
        {"id":"E1","name":"Navidad","date":"2026-12-24T20:00:00Z","budget":null,"status":"draft","participantCount":0}
        """)
        let date = Date(timeIntervalSince1970: 1_798_142_400)

        try await Self.repository().createEvent(CreateRequest(name: "Navidad", date: date))

        let body = try JSONSerialization.jsonObject(
            with: try #require(EventsStubURLProtocol.lastBody)
        ) as? [String: Any]
        #expect(body?["date"] as? String == "2026-12-24T20:00:00Z")
    }

    @Test func decodesTheDetailWithParticipantsAndExclusions() async throws {
        Self.stub(status: 200, body: """
        {"event":{"id":"E1","name":"Navidad","date":null,"budget":30,"status":"draft","participantCount":2},
         "participants":[
           {"id":"P1","name":"Ana","phone":"+34600111222","family":"García","guardianId":null},
           {"id":"P2","name":"Lucía","phone":null,"family":"García","guardianId":"P1"}],
         "exclusions":[{"id":"X1","giverId":"P1","receiverId":"P2"}]}
        """)

        let detail = try await Self.repository().fetchEvent(id: "E1")

        #expect(EventsStubURLProtocol.lastRequest?.url?.absoluteString == "https://backend.test/events/E1")
        #expect(detail.event.id == "E1")
        #expect(detail.participants.map(\.name) == ["Ana", "Lucía"])
        #expect(detail.participants[1].phone == nil)
        #expect(detail.participants[1].guardianId == "P1")
        #expect(detail.exclusions.first?.giverId == "P1")
        #expect(detail.exclusions.first?.receiverId == "P2")
    }

    @Test func deletesAnEventAnsweredWithNoContent() async throws {
        Self.stub(status: 204, body: "")

        try await Self.repository().deleteEvent(id: "E1")

        let sent = try #require(EventsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "DELETE")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1")
    }

    @Test func throwsTheReasonOfTheBackend() async {
        Self.stub(status: 404, body: #"{"error":true,"reason":"Not Found"}"#)

        await #expect(throws: NetworkError.server(statusCode: 404, reason: "Not Found")) {
            try await Self.repository().fetchEvent(id: "missing")
        }
    }

    @Test func throwsTheReasonOfTheBackendOnDelete() async {
        Self.stub(status: 404, body: #"{"error":true,"reason":"Not Found"}"#)

        await #expect(throws: NetworkError.server(statusCode: 404, reason: "Not Found")) {
            try await Self.repository().deleteEvent(id: "missing")
        }
    }

    @Test func requiresASession() async {
        EventsStubURLProtocol.lastRequest = nil
        await #expect(throws: EventsError.notSignedIn) {
            try await Self.repository(session: nil).fetchEvents()
        }
        #expect(EventsStubURLProtocol.lastRequest == nil)
    }

    @Test func rejectsAnExpiredSession() async {
        let expired = AuthResponseDAO(
            token: "old",
            expiresAt: Date().addingTimeInterval(-60),
            userDAO: AuthUserDAO(id: "user-1", name: nil, email: nil)
        )
        await #expect(throws: EventsError.notSignedIn) {
            try await Self.repository(session: expired).fetchEvents()
        }
    }

    @Test func failsWithoutBaseURL() async {
        let configuration = RepositoryConfiguration(baseURL: "", serviceNames: ["events"])
        await #expect(throws: NetworkError.missingBaseURL) {
            try await Self.repository(configuration: configuration).fetchEvents()
        }
    }
}

/// Answers every request with `responseBody` and records the last request.
/// Separate from the Auth tests' stub, so the two suites never share its state.
private final class EventsStubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var responseBody = Data()
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = request.httpBody ?? request.httpBodyStream.map(Self.read)
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: Self.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

/// Session storage kept in memory, so tests do not touch the Keychain.
private actor EventsSessionStorage: AuthSessionStorageProtocol {
    private var session: AuthResponseDAO?

    init(session: AuthResponseDAO?) {
        self.session = session
    }

    func load() async throws -> AuthResponseDAO? { session }
    func save(_ session: AuthResponseDAO) async throws { self.session = session }
    func remove() async throws { session = nil }
}
