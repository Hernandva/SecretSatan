import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    enum State: Equatable {
        case idle
        case loading
        /// The user is signed in: the screen moves on to the next one.
        case loaded
        case failed(String)
    }

    private(set) var state: State = .idle

    private let useCase: any LoginUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: LoginDependencies) {
        self.useCase = dependencies.resolveUseCase()
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
        guard state != .loading else { return }
        state = .loading
        do {
            state = try await useCase.execute(provider: provider) ? .loaded : .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
