import Alamofire
import Foundation
import OSLog

/// Logs every request of `NetworkClient`, under the `SecretSatanData` subsystem and `Network` category.
/// It only logs in Debug builds: in Release both functions are empty, so nothing about the backend reaches the
/// device log. It never logs the request body, which may hold tokens, nor the body of a successful response, which
/// may hold a session token. The body of a failed response is `private`: Xcode's console shows it while debugging,
/// and the system log redacts it.
enum NetworkLog {
    #if DEBUG
    private static let logger = Logger(subsystem: "SecretSatanData", category: "Network")
    /// Longest part of the response body that is logged.
    private static let maxBodyLength = 2_048
    #endif

    static func success(method: RequestMethod, url: URL, response: HTTPURLResponse?, duration: TimeInterval?) {
        #if DEBUG
        logger.info("""
            \(method.name, privacy: .public) \(url.absoluteString, privacy: .public) succeeded \
            (\(status(of: response), privacy: .public))\(elapsed(duration), privacy: .public)
            """)
        #endif
    }

    static func failure(
        _ error: AFError,
        method: RequestMethod,
        url: URL,
        response: HTTPURLResponse?,
        data: Data?
    ) {
        #if DEBUG
        let reason = describe(error)
        let body = data.flatMap { String(data: $0.prefix(maxBodyLength), encoding: .utf8) } ?? ""
        logger.error("""
            \(method.name, privacy: .public) \(url.absoluteString, privacy: .public) failed \
            (\(status(of: response), privacy: .public)): \(reason, privacy: .public). Body: \(body, privacy: .private)
            """)
        #endif
    }

    #if DEBUG
    private static func status(of response: HTTPURLResponse?) -> String {
        response.map { "HTTP \($0.statusCode)" } ?? "no response"
    }

    private static func elapsed(_ duration: TimeInterval?) -> String {
        duration.map { " in \(Int(($0 * 1_000).rounded())) ms" } ?? ""
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
    #endif
}
