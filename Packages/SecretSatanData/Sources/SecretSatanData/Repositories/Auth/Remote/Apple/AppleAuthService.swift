import AuthenticationServices
import CryptoKit
import Foundation

/// Sign in with Apple through `ASAuthorizationController`.
/// The app target needs the "Sign in with Apple" capability (`com.apple.developer.applesignin`).
struct AppleAuthService: AuthProviderService {
    let provider: AuthProvider = .apple

    func signIn(_ request: AuthRequestDAO) async throws -> AuthCredentialDAO {
        let flow = await AppleSignInFlow()
        return try await flow.start()
    }
}

/// One Sign in with Apple attempt. It runs on the main actor, as `ASAuthorizationController` requires, and turns
/// the delegate callbacks into a single async result.
@MainActor
private final class AppleSignInFlow: NSObject {
    private var continuation: CheckedContinuation<AuthCredentialDAO, any Error>?
    /// Raw nonce of this attempt. Apple receives its SHA-256 hash and puts it in the identity token.
    private let nonce = AppleSignInFlow.randomNonce()

    func start() async throws -> AuthCredentialDAO {
        let appleRequest = ASAuthorizationAppleIDProvider().createRequest()
        appleRequest.requestedScopes = [.fullName, .email]
        appleRequest.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [appleRequest])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }
}

private extension AppleSignInFlow {
    func finish(with result: Result<AuthCredentialDAO, any Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }

    func credentialDAO(from authorization: ASAuthorization) throws -> AuthCredentialDAO {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.invalidCredential
        }
        let name = credential.fullName?.formatted()
        return AuthCredentialDAO(
            provider: .apple,
            idToken: idToken,
            nonce: nonce,
            name: name?.isEmpty == false ? name : nil
        )
    }

    /// 32 random bytes as hex.
    static func randomNonce() -> String {
        var generator = SystemRandomNumberGenerator()
        return (0..<32).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max, using: &generator)) }
            .joined()
    }

    static func sha256(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInFlow: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        finish(with: Result { try credentialDAO(from: authorization) })
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
            finish(with: .failure(AuthError.canceled))
        } else {
            finish(with: .failure(error))
        }
    }
}

extension AppleSignInFlow: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        return keyWindow ?? ASPresentationAnchor()
        #else
        return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
        #endif
    }
}
