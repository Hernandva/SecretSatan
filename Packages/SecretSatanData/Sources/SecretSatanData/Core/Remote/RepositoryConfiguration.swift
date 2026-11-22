import Foundation

/// Where a repository's services live. Every repository declares one as `static let configuration`.
public struct RepositoryConfiguration: Sendable, Equatable {
    /// Base URL shared by the repository's services, e.g. "https://api.example.com/v1".
    public let baseURL: String
    /// Names (paths) of the services the repository consumes, e.g. ["users", "users/search"].
    public let serviceNames: [String]

    public init(baseURL: String, serviceNames: [String]) {
        self.baseURL = baseURL
        self.serviceNames = serviceNames
    }

    /// Key of the app's Info.plist that holds the backend base URL. The app sets it from `API_BASE_URL` in
    /// `Configs/Config.xcconfig`.
    static let baseURLInfoKey = "APIBaseURL"

    /// Backend base URL of the running app, read from its Info.plist. Empty when the key is missing (package
    /// tests), so calls fail with `NetworkError.missingBaseURL` instead of reaching a wrong host.
    public static var appBaseURL: String {
        Bundle.main.object(forInfoDictionaryKey: baseURLInfoKey) as? String ?? ""
    }

    /// Full URL of one of the declared services.
    func url(for serviceName: String) throws -> URL {
        guard !baseURL.isEmpty else { throw NetworkError.missingBaseURL }
        guard serviceNames.contains(serviceName) else { throw NetworkError.unknownService(serviceName) }
        // Without a scheme ("api.example.com") URL(string:) still succeeds, but as a relative path that
        // URLSession rejects with NSURLErrorUnsupportedURL (-1002).
        guard
            let base = URL(string: baseURL),
            let scheme = base.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            base.host() != nil
        else {
            throw NetworkError.invalidURL(baseURL)
        }
        return base.appendingPathComponent(serviceName)
    }
}
