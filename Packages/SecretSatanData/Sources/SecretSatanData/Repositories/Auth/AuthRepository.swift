import Foundation

/// Public API of the Auth repository. Features depend on this protocol, never on the concrete class.
public protocol AuthRepositoryProtocol: Sendable {
    /// Signs the user in with `request.provider`, then exchanges the provider's token for a backend session.
    /// Throws `AuthError.unsupportedProvider` when that provider has no service yet,
    /// `AuthError.canceled` when the user closes the sign-in sheet, and `NetworkError` while the configuration
    /// is incomplete.
    func signIn(_ request: some AuthRequestProtocol) async throws -> any AuthResponseProtocol
}

/// Signs users in with several identity providers and opens a session on the backend.
/// Flow: AuthRequestProtocol -> AuthRequestDAO -> provider service (Remote/<Provider>/) -> AuthCredentialDAO
/// -> AuthTokenRequestDAO -> POST /auth/<provider> -> AuthResponseDAO -> AuthResponseProtocol.
public final class AuthRepository: AuthRepositoryProtocol {
    /// Fill in the base URL of the backend. Calls throw `NetworkError.missingBaseURL` while it is empty.
    public static let configuration = RepositoryConfiguration(
        baseURL: "https://secretsanta.hdvillamil.dev",
        serviceNames: AuthProvider.allCases.map(serviceName(for:))
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration
    private let services: [AuthProvider: any AuthProviderService]

    /// Registers one service per supported provider. Add the Google service here when it exists.
    public convenience init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = AuthRepository.configuration
    ) {
        self.init(client: client, configuration: configuration, services: [AppleAuthService()])
    }

    /// Lets tests inject their own provider services.
    init(client: NetworkClient, configuration: RepositoryConfiguration, services: [any AuthProviderService]) {
        self.client = client
        self.configuration = configuration
        self.services = Dictionary(
            services.map { ($0.provider, $0) },
            uniquingKeysWith: { _, last in last }
        )
    }

    public func signIn(_ request: some AuthRequestProtocol) async throws -> any AuthResponseProtocol {
        let requestDAO = AuthRequestDAO(request)
        guard let service = services[requestDAO.provider] else {
            throw AuthError.unsupportedProvider(requestDAO.provider)
        }
        // Resolved before the sign-in sheet, so an incomplete configuration fails without asking the user.
        let url = try configuration.url(for: Self.serviceName(for: requestDAO.provider))
        let credential = try await service.signIn(requestDAO)
        let response: AuthResponseDAO = try await client.request(
            url,
            method: .post,
            body: AuthTokenRequestDAO(credential)
        )
        return response
    }

    /// `auth/apple` and `auth/google`.
    static func serviceName(for provider: AuthProvider) -> String {
        "auth/\(provider.rawValue)"
    }
}
