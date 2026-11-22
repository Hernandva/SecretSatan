import Alamofire
import Foundation
@testable import SecretSatanData
import Testing

@Suite(.serialized)
struct ParticipantsRepositoryTests {
    private struct Request: ParticipantsRequestProtocol {
        let name: String
        var phone: String?
        var guardianId: String?
    }

    private static let eventId = "E1"
    private static let guardianId = "11111111-AAAA-4BBB-8CCC-000000000001"
    private static let childId = "11111111-AAAA-4BBB-8CCC-000000000003"

    private static let backend = RepositoryConfiguration(
        baseURL: "https://backend.test",
        serviceNames: ParticipantsRepository.configuration.serviceNames
    )

    private static let validSession = AuthResponseDAO(
        token: "session-token",
        expiresAt: Date().addingTimeInterval(3_600),
        userDAO: AuthUserDAO(id: "user-1", name: nil, email: nil)
    )

    @Test func declaresTheEventsService() {
        #expect(ParticipantsRepository.configuration.serviceNames == ["events"])
    }

    @Test func addsAnAdultWithOnlyTheFieldsItHas() async throws {
        Self.stub(status: 200, body: """
        {"id":"\(Self.guardianId)","name":"Ana","phone":"+34600111222","family":"García","guardianId":null}
        """)

        let participant = try await Self.repository().addParticipant(
            eventId: Self.eventId,
            Request(name: "Ana", phone: "+34600111222")
        )

        let sent = try #require(ParticipantsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/participants")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer session-token")
        let body = try Self.sentBody()
        #expect(body?.keys.sorted() == ["name", "phone"])
        #expect(body?["phone"] as? String == "+34600111222")
        #expect(participant.id == Self.guardianId)
        #expect(participant.guardianId == nil)
    }

    @Test func addsAChildWithAGuardian() async throws {
        Self.stub(status: 200, body: """
        {"id":"\(Self.childId)","name":"Lucía","phone":null,"family":"García","guardianId":"\(Self.guardianId)"}
        """)

        let participant = try await Self.repository().addParticipant(
            eventId: Self.eventId,
            Request(name: "Lucía", guardianId: Self.guardianId)
        )

        let body = try Self.sentBody()
        #expect(body?.keys.sorted() == ["guardianId", "name"])
        #expect(participant.id == Self.childId)
        #expect(participant.name == "Lucía")
        #expect(participant.phone == nil)
        #expect(participant.guardianId == Self.guardianId)
    }

    @Test func updatesEveryFieldSendingTheEmptyOnesAsNull() async throws {
        Self.stub(status: 200, body: """
        {"id":"\(Self.guardianId)","name":"Ana María","phone":"+34600999888","family":"García","guardianId":null}
        """)

        let participant = try await Self.repository().updateParticipant(
            eventId: Self.eventId,
            participantId: Self.guardianId,
            Request(name: "Ana María", phone: "+34600999888")
        )

        let sent = try #require(ParticipantsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "PUT")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/participants/\(Self.guardianId)")
        let body = try Self.sentBody()
        #expect(body?.keys.sorted() == ["guardianId", "name", "phone"])
        #expect(body?["guardianId"] is NSNull)
        #expect(participant.name == "Ana María")
        #expect(participant.phone == "+34600999888")
    }

    @Test func deletesAParticipantAnsweredWithNoContent() async throws {
        Self.stub(status: 204, body: "")

        try await Self.repository().deleteParticipant(eventId: Self.eventId, participantId: Self.childId)

        let sent = try #require(ParticipantsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "DELETE")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/participants/\(Self.childId)")
    }

    @Test func fetchesTheWardsOfAGuardian() async throws {
        Self.stub(status: 200, body: """
        [
          {"id":"\(Self.childId)","name":"Lucía","phone":null,"guardianId":"\(Self.guardianId)"},
          {"id":"11111111-AAAA-4BBB-8CCC-000000000004","name":"Pablo","phone":null,"guardianId":"\(Self.guardianId)"}
        ]
        """)

        let wards = try await Self.repository().fetchWards(eventId: Self.eventId, participantId: Self.guardianId)

        let sent = try #require(ParticipantsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "GET")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/participants/\(Self.guardianId)/wards")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer session-token")
        #expect(wards.map(\.name) == ["Lucía", "Pablo"])
        #expect(wards.allSatisfy { $0.phone == nil && $0.guardianId == Self.guardianId })
    }

    @Test func fetchesNoWardsForAParticipantWhoIsNobodysGuardian() async throws {
        Self.stub(status: 200, body: "[]")

        let wards = try await Self.repository().fetchWards(eventId: Self.eventId, participantId: Self.childId)

        #expect(wards.isEmpty)
    }

    @Test func fetchesTheParticipantsItMustNotBeAssigned() async throws {
        Self.stub(status: 200, body: """
        [
          {"id":"11111111-AAAA-4BBB-8CCC-000000000002","name":"Bruno","phone":"+34600333444","guardianId":null},
          {"id":"11111111-AAAA-4BBB-8CCC-000000000005","name":"Carla","phone":"+34600555666","guardianId":null}
        ]
        """)

        let excluded = try await Self.repository().fetchExcluded(eventId: Self.eventId, participantId: Self.guardianId)

        let sent = try #require(ParticipantsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "GET")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/participants/\(Self.guardianId)/excluded")
        #expect(excluded.map(\.name) == ["Bruno", "Carla"])
        #expect(excluded.map(\.phone) == ["+34600333444", "+34600555666"])
        #expect(excluded.allSatisfy { $0.guardianId == nil })
    }

    @Test func throwsNotFoundForTheExclusionsOfAParticipantOfAnotherEvent() async {
        Self.stub(status: 404, body: #"{"error":true,"reason":"Not Found"}"#)

        await #expect(throws: NetworkError.server(statusCode: 404, reason: "Not Found")) {
            try await Self.repository().fetchExcluded(eventId: Self.eventId, participantId: "missing")
        }
    }

    @Test func throwsTheReasonOfTheBackendWhenThereIsNoPhoneOrGuardian() async {
        let reason = "Indica un teléfono o un tutor que reciba el enlace."
        Self.stub(status: 400, body: #"{"error":true,"reason":"\#(reason)"}"#)

        await #expect(throws: NetworkError.server(statusCode: 400, reason: reason)) {
            try await Self.repository().addParticipant(eventId: Self.eventId, Request(name: "Lucía"))
        }
    }

    @Test func fetchesTheLinkOfAParticipantWithoutABody() async throws {
        let participantId = "11111111-AAAA-4BBB-8CCC-000000000002"
        let link = "https://secretsanta.hdvillamil.dev/r/Lm7nB3vC9xZ1aS5dF8gH2jK6lQ0wE4rT-yU_iO7pA3s"
        let message = "🎁 Amigo secreto de Bruno (Navidad familia 2026). Abre el enlace tú solo: funciona una única vez."
        Self.stub(status: 200, body: """
        {"participantId":"\(participantId)","name":"Bruno","url":"\(link)",
         "message":"\(message)\\n\(link)","deliverToName":"Bruno","deliverToPhone":"+34600333444"}
        """)

        let response = try await Self.repository().fetchLink(eventId: Self.eventId, participantId: participantId)

        #expect(response.participantId == participantId)
        #expect(response.name == "Bruno")
        #expect(response.url == URL(string: link))
        #expect(response.message == "\(message)\n\(link)")
        #expect(response.deliverToName == "Bruno")
        #expect(response.deliverToPhone == "+34600333444")
        let sent = try #require(ParticipantsStubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "https://backend.test/events/E1/participants/\(participantId)/link")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer session-token")
        #expect(ParticipantsStubURLProtocol.lastBody?.isEmpty ?? true)
    }

    @Test func throwsTheReasonOfTheBackendAfterTheDraw() async {
        let reason = "El sorteo ya se hizo; no se pueden quitar participantes."
        Self.stub(status: 409, body: #"{"error":true,"reason":"\#(reason)"}"#)

        await #expect(throws: NetworkError.server(statusCode: 409, reason: reason)) {
            try await Self.repository().deleteParticipant(eventId: Self.eventId, participantId: Self.childId)
        }
    }

    @Test func throwsNotFoundForAParticipantOfAnotherEvent() async {
        Self.stub(status: 404, body: #"{"error":true,"reason":"Not Found"}"#)

        await #expect(throws: NetworkError.server(statusCode: 404, reason: "Not Found")) {
            try await Self.repository().updateParticipant(
                eventId: Self.eventId,
                participantId: "missing",
                Request(name: "Ana", phone: "+34600111222")
            )
        }
    }

    @Test func requiresASession() async {
        ParticipantsStubURLProtocol.lastRequest = nil
        await #expect(throws: ParticipantsError.notSignedIn) {
            try await Self.repository(session: nil).deleteParticipant(eventId: Self.eventId, participantId: "P1")
        }
        await #expect(throws: ParticipantsError.notSignedIn) {
            try await Self.repository(session: nil).fetchWards(eventId: Self.eventId, participantId: "P1")
        }
        #expect(ParticipantsStubURLProtocol.lastRequest == nil)
    }

    @Test func failsWithoutBaseURL() async {
        let configuration = RepositoryConfiguration(baseURL: "", serviceNames: ["events"])
        await #expect(throws: NetworkError.missingBaseURL) {
            try await Self.repository(configuration: configuration).addParticipant(
                eventId: Self.eventId,
                Request(name: "Ana", phone: "+34600111222")
            )
        }
    }
}

private extension ParticipantsRepositoryTests {
    static func repository(
        configuration: RepositoryConfiguration = backend,
        session: AuthResponseDAO? = validSession
    ) -> ParticipantsRepository {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [ParticipantsStubURLProtocol.self]
        let client = NetworkClient(session: Session(configuration: sessionConfiguration))
        return ParticipantsRepository(
            client: client,
            configuration: configuration,
            sessionStorage: ParticipantsSessionStorage(session: session)
        )
    }

    static func stub(status: Int, body: String) {
        ParticipantsStubURLProtocol.statusCode = status
        ParticipantsStubURLProtocol.responseBody = Data(body.utf8)
    }

    /// JSON object sent in the body of the last request.
    static func sentBody() throws -> [String: Any]? {
        try JSONSerialization.jsonObject(with: try #require(ParticipantsStubURLProtocol.lastBody)) as? [String: Any]
    }
}

/// Answers every request with `responseBody` and records the last request.
/// Separate from the other suites' stubs, so they never share its state.
private final class ParticipantsStubURLProtocol: URLProtocol, @unchecked Sendable {
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

private extension ParticipantsStubURLProtocol {
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
private actor ParticipantsSessionStorage: AuthSessionStorageProtocol {
    private var session: AuthResponseDAO?

    init(session: AuthResponseDAO?) {
        self.session = session
    }

    func load() async throws -> AuthResponseDAO? { session }
    func save(_ session: AuthResponseDAO) async throws { self.session = session }
    func remove() async throws { session = nil }
}
