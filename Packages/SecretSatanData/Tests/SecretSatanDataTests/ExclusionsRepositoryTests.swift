import Alamofire
import Foundation
@testable import SecretSatanData
import Testing

@Suite(.serialized)
struct ExclusionsRepositoryTests {
    private struct Request: ExclusionsRequestProtocol {
        let giverId: String
        let receiverId: String
    }

    private static let eventId = "E1"
    private static let anaId = "11111111-AAAA-4BBB-8CCC-000000000001"
    private static let brunoId = "11111111-AAAA-4BBB-8CCC-000000000002"
    private static let firstExclusionId = "22222222-DDDD-4EEE-8FFF-000000000001"
    private static let secondExclusionId = "22222222-DDDD-4EEE-8FFF-000000000002"

    private static let backend = RepositoryConfiguration(
        baseURL: "https://backend.test",
        serviceNames: ExclusionsRepository.configuration.serviceNames
    )

    private static let validSession = AuthResponseDAO(
        token: "session-token",
        expiresAt: Date().addingTimeInterval(3_600),
        userDAO: AuthUserDAO(id: "user-1", name: nil, email: nil)
    )

    @Test func declaresTheEventsService() {
        #expect(ExclusionsRepository.configuration.serviceNames == ["events"])
    }

    @Test func createsAnExclusionInBothDirections() async throws {
        Self.stub(status: 200, body: """
        [
          {"id":"\(Self.firstExclusionId)","giverId":"\(Self.anaId)","receiverId":"\(Self.brunoId)"},
          {"id":"\(Self.secondExclusionId)","giverId":"\(Self.brunoId)","receiverId":"\(Self.anaId)"}
        ]
        """)

        let exclusions = try await Self.repository().createExclusion(
            eventId: Self.eventId,
            Request(giverId: Self.anaId, receiverId: Self.brunoId)
        )

        let sent = try #require(ExclusionsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/exclusions")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer session-token")
        let body = try Self.sentBody()
        #expect(body?.keys.sorted() == ["giverId", "receiverId"])
        #expect(body?["giverId"] as? String == Self.anaId)
        #expect(body?["receiverId"] as? String == Self.brunoId)
        #expect(exclusions.map(\.id) == [Self.firstExclusionId, Self.secondExclusionId])
        #expect(exclusions.map(\.giverId) == [Self.anaId, Self.brunoId])
        #expect(exclusions.map(\.receiverId) == [Self.brunoId, Self.anaId])
    }

    @Test func returnsOnlyTheMissingDirection() async throws {
        Self.stub(status: 200, body: """
        [{"id":"\(Self.secondExclusionId)","giverId":"\(Self.brunoId)","receiverId":"\(Self.anaId)"}]
        """)

        let exclusions = try await Self.repository().createExclusion(
            eventId: Self.eventId,
            Request(giverId: Self.anaId, receiverId: Self.brunoId)
        )

        #expect(exclusions.map(\.id) == [Self.secondExclusionId])
    }

    @Test func returnsNothingWhenBothDirectionsExisted() async throws {
        Self.stub(status: 200, body: "[]")

        let exclusions = try await Self.repository().createExclusion(
            eventId: Self.eventId,
            Request(giverId: Self.anaId, receiverId: Self.brunoId)
        )

        #expect(exclusions.isEmpty)
    }

    @Test func deletesAnExclusionAnsweredWithNoContent() async throws {
        Self.stub(status: 204, body: "")

        try await Self.repository().deleteExclusion(eventId: Self.eventId, exclusionId: Self.firstExclusionId)

        let sent = try #require(ExclusionsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "DELETE")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/exclusions/\(Self.firstExclusionId)")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer session-token")
    }

    @Test func throwsTheReasonOfTheBackend() async {
        Self.stub(status: 404, body: #"{"error":true,"reason":"Not Found"}"#)

        await #expect(throws: NetworkError.server(statusCode: 404, reason: "Not Found")) {
            try await Self.repository().deleteExclusion(eventId: Self.eventId, exclusionId: "missing")
        }
    }

    @Test func requiresASession() async {
        ExclusionsStubURLProtocol.lastRequest = nil
        await #expect(throws: ExclusionsError.notSignedIn) {
            try await Self.repository(session: nil).createExclusion(
                eventId: Self.eventId,
                Request(giverId: Self.anaId, receiverId: Self.brunoId)
            )
        }
        await #expect(throws: ExclusionsError.notSignedIn) {
            try await Self.repository(session: nil).deleteExclusion(eventId: Self.eventId, exclusionId: "X1")
        }
        #expect(ExclusionsStubURLProtocol.lastRequest == nil)
    }

    @Test func failsWithoutBaseURL() async {
        let configuration = RepositoryConfiguration(baseURL: "", serviceNames: ["events"])
        await #expect(throws: NetworkError.missingBaseURL) {
            try await Self.repository(configuration: configuration).deleteExclusion(
                eventId: Self.eventId,
                exclusionId: Self.firstExclusionId
            )
        }
    }
}

private extension ExclusionsRepositoryTests {
    static func repository(
        configuration: RepositoryConfiguration = backend,
        session: AuthResponseDAO? = validSession
    ) -> ExclusionsRepository {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [ExclusionsStubURLProtocol.self]
        let client = NetworkClient(session: Session(configuration: sessionConfiguration))
        return ExclusionsRepository(
            client: client,
            configuration: configuration,
            sessionStorage: ExclusionsSessionStorage(session: session)
        )
    }

    static func stub(status: Int, body: String) {
        ExclusionsStubURLProtocol.statusCode = status
        ExclusionsStubURLProtocol.responseBody = Data(body.utf8)
    }

    /// JSON object sent in the body of the last request.
    static func sentBody() throws -> [String: Any]? {
        try JSONSerialization.jsonObject(with: try #require(ExclusionsStubURLProtocol.lastBody)) as? [String: Any]
    }
}

/// Answers every request with `responseBody` and records the last request.
/// Separate from the other suites' stubs, so they never share its state.
private final class ExclusionsStubURLProtocol: URLProtocol, @unchecked Sendable {
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
}

private extension ExclusionsStubURLProtocol {
    static func read(_ stream: InputStream) -> Data {
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
private actor ExclusionsSessionStorage: AuthSessionStorageProtocol {
    private var session: AuthResponseDAO?

    init(session: AuthResponseDAO?) {
        self.session = session
    }

    func load() async throws -> AuthResponseDAO? { session }
    func save(_ session: AuthResponseDAO) async throws { self.session = session }
    func remove() async throws { session = nil }
}
