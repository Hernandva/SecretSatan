import Foundation

public enum NetworkError: Error, Equatable, Sendable {
    /// The repository's `configuration.baseURL` is still empty.
    case missingBaseURL
    /// The service name is not listed in the repository's `configuration.serviceNames`.
    case unknownService(String)
    /// The base URL cannot be parsed, or it has no `http`/`https` scheme or no host.
    case invalidURL(String)
    /// The backend rejected the request with its error body, `{ "error": true, "reason": "…" }`.
    /// `reason` is the backend's message, e.g. "El nombre es obligatorio." or "Not Found".
    case server(statusCode: Int, reason: String)
}
