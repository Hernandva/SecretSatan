import Foundation

/// Dependency injection container of Home: the only place where its concrete types are built.
/// View, ViewModel and UseCase receive it in their `init(dependencies:)` and call the `resolve` functions they need.
@MainActor
final class HomeDependencies {
    init() {}

    func resolveUseCase() -> any HomeUseCaseProtocol {
        HomeUseCase(dependencies: self)
    }

    func resolveViewModel() -> HomeViewModel {
        HomeViewModel(dependencies: self)
    }
}
