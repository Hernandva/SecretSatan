import Alamofire
import Foundation

/// HTTP verbs available to repositories. Keeps Alamofire types out of repository code.
enum RequestMethod: Sendable {
    case get
    case post
    case put
    case patch
    case delete

    /// Verb as sent on the wire, e.g. "POST".
    var name: String {
        alamofireMethod.rawValue
    }

    var alamofireMethod: HTTPMethod {
        switch self {
        case .get: .get
        case .post: .post
        case .put: .put
        case .patch: .patch
        case .delete: .delete
        }
    }
}

/// The only type in the project that talks to Alamofire.
/// Repositories receive it in their initialiser so tests can inject a session with stubbed responses.
public final class NetworkClient: @unchecked Sendable {
    // `Session` is thread safe; the client holds no mutable state.
    public static let shared = NetworkClient()

    private let session: Session

    public init(session: Session = .default) {
        self.session = session
    }

    /// Sends `body` (query string for GET, JSON otherwise) and decodes the response DAO.
    func request<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ url: URL,
        method: RequestMethod,
        body: Body?,
        headers: [String: String] = [:]
    ) async throws -> Response {
        let encoder: any ParameterEncoder = method == .get
            ? URLEncodedFormParameterEncoder.default
            : JSONParameterEncoder.default
        let dataRequest = session.request(
            url,
            method: method.alamofireMethod,
            parameters: body,
            encoder: encoder,
            headers: HTTPHeaders(headers)
        )
        return try await decode(dataRequest, method: method, url: url)
    }

    /// Sends a request without a body and decodes the response DAO.
    func request<Response: Decodable & Sendable>(
        _ url: URL,
        method: RequestMethod,
        headers: [String: String] = [:]
    ) async throws -> Response {
        let dataRequest = session.request(url, method: method.alamofireMethod, headers: HTTPHeaders(headers))
        return try await decode(dataRequest, method: method, url: url)
    }

    /// Sends a request without a body whose response has no body either, e.g. a `DELETE` answered with `204`.
    func send(_ url: URL, method: RequestMethod, headers: [String: String] = [:]) async throws {
        let response = await session
            .request(url, method: method.alamofireMethod, headers: HTTPHeaders(headers))
            .validate()
            .serializingData(emptyResponseCodes: [200, 204, 205])
            .response
        switch response.result {
        case .success:
            NetworkLog.success(
                method: method,
                url: url,
                response: response.response,
                duration: response.metrics?.taskInterval.duration
            )
        case .failure(let error):
            NetworkLog.failure(error, method: method, url: url, response: response.response, data: response.data)
            throw Self.error(for: error, response: response.response, data: response.data)
        }
    }

    private func decode<Response: Decodable & Sendable>(
        _ dataRequest: DataRequest,
        method: RequestMethod,
        url: URL
    ) async throws -> Response {
        let response = await dataRequest
            .validate()
            .serializingDecodable(Response.self)
            .response
        switch response.result {
        case .success(let value):
            NetworkLog.success(
                method: method,
                url: url,
                response: response.response,
                duration: response.metrics?.taskInterval.duration
            )
            return value
        case .failure(let error):
            NetworkLog.failure(error, method: method, url: url, response: response.response, data: response.data)
            throw Self.error(for: error, response: response.response, data: response.data)
        }
    }

    /// `NetworkError.server` when the backend answered with its error body, the Alamofire error otherwise.
    private static func error(for error: AFError, response: HTTPURLResponse?, data: Data?) -> any Error {
        guard
            let response,
            let data,
            let body = try? JSONDecoder().decode(ServerErrorDAO.self, from: data),
            body.error
        else {
            return error
        }
        return NetworkError.server(statusCode: response.statusCode, reason: body.reason)
    }
}

/// Error body of the backend (Vapor): `{ "error": true, "reason": "…" }`.
private struct ServerErrorDAO: Decodable {
    let error: Bool
    let reason: String
}
