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

    func load() async {
        state = .loading
        do {
            viewData.content = try await useCase.execute()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// "Continuar con Apple". Sign in with Apple is not connected yet.
    func continueWithApple() {}

    /// "Continuar con Google". Google sign-in is not connected yet.
    func continueWithGoogle() {}
}
