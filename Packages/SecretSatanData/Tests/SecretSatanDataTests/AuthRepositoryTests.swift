import Alamofire
import Foundation
@testable import SecretSatanData
import Testing

@Suite(.serialized)
struct AuthRepositoryTests {
    private struct Request: AuthRequestProtocol {
        let provider: AuthProvider
    }

    private struct StubService: AuthProviderService {
        let provider: AuthProvider

        func signIn(_ request: AuthRequestDAO) async throws -> AuthCredentialDAO {
            AuthCredentialDAO(provider: provider, idToken: "provider-token", nonce: "raw-nonce", name: nil)
        }
    }

    private static let backend = RepositoryConfiguration(
        baseURL: "https://backend.test",
        serviceNames: AuthRepository.configuration.serviceNames
    )

    private static func repository(
        configuration: RepositoryConfiguration = backend,
        services: [any AuthProviderService]
    ) -> AuthRepository {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [StubURLProtocol.self]
        let client = NetworkClient(session: Session(configuration: sessionConfiguration))
        return AuthRepository(client: client, configuration: configuration, services: services)
    }

    @Test func declaresOneServicePerProvider() {
        #expect(AuthRepository.configuration.serviceNames == ["auth/apple", "auth/google"])
    }

    @Test(arguments: AuthProvider.allCases)
    func postsTheProviderTokenAndDecodesTheSession(provider: AuthProvider) async throws {
        StubURLProtocol.statusCode = 200
        StubURLProtocol.responseBody = Data("""
        {"token":"session-token","expiresAt":"2026-12-01T10:00:00Z",
         "user":{"id":"user-1","name":"Ana","email":"ana@example.com"}}
        """.utf8)
        let repository = Self.repository(services: [StubService(provider: provider)])

        let response = try await repository.signIn(Request(provider: provider))

        let sent = try #require(StubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "https://backend.test/auth/\(provider.rawValue)")
        let body = try JSONSerialization.jsonObject(with: try #require(StubURLProtocol.lastBody)) as? [String: String]
        #expect(body == ["idToken": "provider-token", "nonce": "raw-nonce"])
        #expect(response.token == "session-token")
        #expect(response.expiresAt == Date(timeIntervalSince1970: 1_796_119_200))
        #expect(response.user.id == "user-1")
        #expect(response.user.email == "ana@example.com")
    }

    @Test func throwsTheStatusCodeOfARejectedToken() async {
        StubURLProtocol.statusCode = 401
        StubURLProtocol.responseBody = Data(#"{"error":"invalid idToken"}"#.utf8)
        let repository = Self.repository(services: [StubService(provider: .apple)])
        do {
            _ = try await repository.signIn(Request(provider: .apple))
            Issue.record("Expected the 401 to throw")
        } catch let error as AFError {
            #expect(error.responseCode == 401)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func throwsForAProviderWithoutService() async {
        let repository = Self.repository(services: [StubService(provider: .apple)])
        await #expect(throws: AuthError.unsupportedProvider(.google)) {
            try await repository.signIn(Request(provider: .google))
        }
    }

    @Test func failsBeforeTheSignInSheetWithoutBaseURL() async {
        let configuration = RepositoryConfiguration(baseURL: "", serviceNames: ["auth/apple"])
        let repository = Self.repository(configuration: configuration, services: [StubService(provider: .apple)])
        await #expect(throws: NetworkError.missingBaseURL) {
            try await repository.signIn(Request(provider: .apple))
        }
    }

    @Test func decodesExpiresAtWithFractionalSecondsOrTimestamp() throws {
        let decoder = JSONDecoder()
        let user = #""user":{"id":"u"}"#
        let fractional = try decoder.decode(
            AuthResponseDAO.self,
            from: Data(#"{"token":"t","expiresAt":"2026-12-01T10:00:00.500Z",\#(user)}"#.utf8)
        )
        let timestamp = try decoder.decode(
            AuthResponseDAO.self,
            from: Data(#"{"token":"t","expiresAt":1796119200,\#(user)}"#.utf8)
        )
        #expect(fractional.expiresAt == Date(timeIntervalSince1970: 1_796_119_200.5))
        #expect(timestamp.expiresAt == Date(timeIntervalSince1970: 1_796_119_200))
        #expect(timestamp.user.name == nil)
    }
}

/// Answers every request with `responseBody` and records the last request.
private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
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
