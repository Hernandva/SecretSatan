import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    enum State: Equatable {
        case idle
        /// Reading the saved session, before the screen shows any button.
        case checkingSession
        case loading
        /// The user is signed in: the screen shows "Enter".
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Data of the screen. Each use case result updates only its own field.
    private(set) var viewData = LoginViewData()

    private let useCase: any LoginUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: LoginDependencies) {
        self.useCase = dependencies.resolveUseCase()
    }

    /// Reads the saved session. A session that cannot be read counts as no session, so the user can sign in again.
    func checkSession() async {
        guard state == .idle else { return }
        state = .checkingSession
        viewData.hasSession = (try? await useCase.hasValidSession()) ?? false
        state = viewData.hasSession ? .loaded : .idle
    }

    /// "Continuar con Apple".
    func continueWithApple() async {
        await signIn(with: .apple)
    }

    /// "Continuar con Google". Fails until SecretSatanData has a Google service.
    func continueWithGoogle() async {
        await signIn(with: .google)
    }

    private func signIn(with provider: LoginProvider) async {
        guard state != .loading, state != .checkingSession else { return }
        state = .loading
        do {
            viewData.hasSession = try await useCase.execute(provider: provider)
            state = viewData.hasSession ? .loaded : .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
