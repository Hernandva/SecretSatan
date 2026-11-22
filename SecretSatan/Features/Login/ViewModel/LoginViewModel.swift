import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    enum State: Equatable {
        case idle
        case loading
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
            guard let session = try await useCase.execute(provider: provider) else {
                state = .idle
                return
            }
            viewData.session = session
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
