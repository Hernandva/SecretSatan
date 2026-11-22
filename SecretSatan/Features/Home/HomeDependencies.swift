import Foundation
import SecretSatanData

/// Dependency injection container of Home: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class HomeDependencies {
    private let repository: any AuthRepositoryProtocol

    init(repository: any AuthRepositoryProtocol = AuthRepository()) {
        self.repository = repository
    }

    func resolveRepository() -> any AuthRepositoryProtocol {
        repository
    }

    func resolveUseCase() -> any HomeUseCaseProtocol {
        HomeUseCase(dependencies: self)
    }

    func resolveViewModel() -> HomeViewModel {
        HomeViewModel(dependencies: self)
    }
}
