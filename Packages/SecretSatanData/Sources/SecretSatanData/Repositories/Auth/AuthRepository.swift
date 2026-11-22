import Foundation

/// Public API of the Auth repository. Features depend on this protocol, never on the concrete class.
public protocol AuthRepositoryProtocol: Sendable {
    /// Signs the user in with `request.provider`, exchanges the provider's token for a backend session and saves it
    /// on the device. Throws `AuthError.unsupportedProvider` when that provider has no service yet,
    /// `AuthError.canceled` when the user closes the sign-in sheet, `NetworkError` while the configuration is
    /// incomplete, and `LocalStoreError` when the session cannot be saved.
    @discardableResult
    func signIn(_ request: some AuthRequestProtocol) async throws -> any AuthResponseProtocol

    /// The saved session, or `nil` when the user has not signed in or it has expired.
    func currentSession() async throws -> (any AuthResponseProtocol)?
}

/// Signs users in with several identity providers, opens a session on the backend and keeps it in the Keychain.
/// Flow: AuthRequestProtocol -> AuthRequestDAO -> provider service (Remote/<Provider>/) -> AuthCredentialDAO
/// -> AuthTokenRequestDAO -> POST /auth/<provider> -> AuthResponseDAO -> AuthSessionStorage (Local/)
/// -> AuthResponseProtocol.
public final class AuthRepository: AuthRepositoryProtocol {
    /// Services of the backend, on the base URL of the app's Info.plist (`API_BASE_URL` in Config.xcconfig).
    public static let configuration = RepositoryConfiguration(
        baseURL: RepositoryConfiguration.appBaseURL,
        serviceNames: AuthProvider.allCases.map(serviceName(for:))
    )

    private let client: NetworkClient
    private let configuration: RepositoryConfiguration
    private let services: [AuthProvider: any AuthProviderService]
    private let storage: any AuthSessionStorageProtocol

    /// Registers one service per supported provider. Add the Google service here when it exists.
    public convenience init(
        client: NetworkClient = .shared,
        configuration: RepositoryConfiguration = AuthRepository.configuration
    ) {
        self.init(
            client: client,
            configuration: configuration,
            services: [AppleAuthService()],
            storage: AuthSessionStorage()
        )
    }

    /// Lets tests inject their own provider services and storage.
    init(
        client: NetworkClient,
        configuration: RepositoryConfiguration,
        services: [any AuthProviderService],
        storage: any AuthSessionStorageProtocol
    ) {
        self.client = client
        self.configuration = configuration
        self.services = Dictionary(
            services.map { ($0.provider, $0) },
            uniquingKeysWith: { _, last in last }
        )
        self.storage = storage
    }

    @discardableResult
    public func signIn(_ request: some AuthRequestProtocol) async throws -> any AuthResponseProtocol {
        let requestDAO = AuthRequestDAO(request)
        guard let service = services[requestDAO.provider] else {
            throw AuthError.unsupportedProvider(requestDAO.provider)
        }
        // Resolved before the sign-in sheet, so an incomplete configuration fails without asking the user.
        let url = try configuration.url(for: Self.serviceName(for: requestDAO.provider))
        let credential = try await service.signIn(requestDAO)
        let session: AuthResponseDAO = try await client.request(
            url,
            method: .post,
            body: AuthTokenRequestDAO(credential)
        )
        try await storage.save(session)
        return session
    }

    public func currentSession() async throws -> (any AuthResponseProtocol)? {
        guard let session = try await storage.load() else { return nil }
        guard session.expiresAt > Date() else {
            try await storage.remove()
            return nil
        }
        return session
    }

    /// `auth/apple` and `auth/google`.
    static func serviceName(for provider: AuthProvider) -> String {
        "auth/\(provider.rawValue)"
    }
}
