import Foundation

/// Public API of the Auth repository. Features depend on this protocol, never on the concrete class.
public protocol AuthRepositoryProtocol: Sendable {
    /// Calls one of the services in `AuthRepository.configuration.serviceNames`.
    func fetch(
        _ request: some AuthRequestProtocol,
        serviceName: String
    ) async throws -> any AuthResponseProtocol
}

/// Talks to the Auth services.
/// Flow: AuthRequestProtocol -> AuthRequestDAO -> AuthResponseDAO -> AuthResponseProtocol.
public final class AuthRepository: AuthRepositoryProtocol {
    /// Fill in the base URL and the names of the services this repository consumes.
    public static let configuration = RepositoryConfiguration(
        baseURL: "",
        serviceNames: []
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration

    public init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = AuthRepository.configuration
    ) {
        self.client = client
        self.configuration = configuration
    }

    public func fetch(
        _ request: some AuthRequestProtocol,
        serviceName: String
    ) async throws -> any AuthResponseProtocol {
        let url = try configuration.url(for: serviceName)
        let requestDAO = AuthRequestDAO(request)
        let responseDAO: AuthResponseDAO = try await client.request(url, method: .get, body: requestDAO)
        return responseDAO
    }
}
