import Foundation
import SecretSatanData

/// Dependency injection container of Login: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class LoginDependencies {
    private let repository: any AuthRepositoryProtocol

    init(repository: any AuthRepositoryProtocol = AuthRepository()) {
        self.repository = repository
    }

    func resolveRepository() -> any AuthRepositoryProtocol {
        repository
    }

    func resolveUseCase() -> any LoginUseCaseProtocol {
        LoginUseCase(dependencies: self)
    }

    func resolveViewModel() -> LoginViewModel {
        LoginViewModel(dependencies: self)
    }
}
