import Alamofire
import Foundation
import OSLog

/// Logs the requests of `NetworkClient` that fail: transport errors, non-2xx status codes and responses that
/// cannot be decoded. It never logs the request body, which may hold tokens. The response body is `private`:
/// Xcode's console shows it while debugging, and the system log redacts it on other devices.
enum NetworkLog {
    private static let logger = Logger(subsystem: "SecretSatanData", category: "Network")
    /// Longest part of the response body that is logged.
    private static let maxBodyLength = 2_048

    static func failure(
        _ error: AFError,
        method: RequestMethod,
        url: URL,
        response: HTTPURLResponse?,
        data: Data?
    ) {
        let status = response.map { "HTTP \($0.statusCode)" } ?? "no response"
        let reason = describe(error)
        let body = data.flatMap { String(data: $0.prefix(maxBodyLength), encoding: .utf8) } ?? ""
        logger.error("""
            \(method.name, privacy: .public) \(url.absoluteString, privacy: .public) failed \
            (\(status, privacy: .public)): \(reason, privacy: .public). Body: \(body, privacy: .private)
            """)
    }

    /// The most useful description of an Alamofire error: the decoding or transport error it wraps, if any.
    private static func describe(_ error: AFError) -> String {
        switch error {
        case .responseValidationFailed(reason: .unacceptableStatusCode(let code)):
            return "unacceptable status code \(code)"
        case .responseSerializationFailed(reason: .decodingFailed(let decodingError)):
            return "decoding failed: \(decodingError)"
        default:
            if let underlying = error.underlyingError {
                return "\(error.localizedDescription) [\(underlying)]"
            }
            return error.localizedDescription
        }
    }
}
