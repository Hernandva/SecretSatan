import Foundation
import SecretSatanData

/// Errors of `AddExclusionUseCase` that the sheet can show.
enum AddExclusionError: Error, Equatable {
    /// The backend refused the exclusion, with its message.
    case rejected(String)
}

protocol AddExclusionUseCaseProtocol: Sendable {
    /// Makes the selected participant and `receiverId` never be assigned to each other in the draw.
    /// Throws `AddExclusionError.rejected` when the backend refuses it.
    func execute(receiverId: String) async throws
}

/// Creates an exclusion between the selected participant and another one through the Exclusions repository
/// (`POST /events/:id/exclusions`). The backend saves it in both directions.
struct AddExclusionUseCase: AddExclusionUseCaseProtocol {
    private struct Request: ExclusionsRequestProtocol {
        let giverId: String
        let receiverId: String
    }

    private let repository: any ExclusionsRepositoryProtocol
    private let eventId: String
    private let giverId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.repository = dependencies.resolveExclusionsRepository()
        self.eventId = dependencies.resolveEventId()
        self.giverId = dependencies.resolveParticipant().id
    }

    func execute(receiverId: String) async throws {
        do {
            try await repository.createExclusion(
                eventId: eventId,
                Request(giverId: giverId, receiverId: receiverId)
            )
        } catch NetworkError.server(_, let reason) {
            throw AddExclusionError.rejected(reason)
        }
    }
}
