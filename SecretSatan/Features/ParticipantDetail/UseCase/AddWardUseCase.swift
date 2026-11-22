import Foundation
import SecretSatanData

/// Errors of `AddWardUseCase` that the sheet can show.
enum AddWardError: Error, Equatable {
    /// The backend refused the ward, with its message, e.g. when the guardian has no phone.
    case rejected(String)
}

protocol AddWardUseCaseProtocol: Sendable {
    /// Adds a participant without a phone whose guardian is the selected participant, and returns it as a row of
    /// "Protegidos". Throws `AddWardError.rejected` when the backend refuses it.
    func execute(name: String) async throws -> ParticipantDetailViewData.Member
}

/// Adds a ward of the selected participant to the event through the Participants repository
/// (`POST /events/:id/participants` with `guardianId`) and returns only the data the list shows.
struct AddWardUseCase: AddWardUseCaseProtocol {
    private struct Request: ParticipantsRequestProtocol {
        let name: String
        /// A ward has no phone: its guardian receives its link.
        let phone: String? = nil
        let guardianId: String?
    }

    private let repository: any ParticipantsRepositoryProtocol
    private let eventId: String
    private let guardianId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEventId()
        self.guardianId = dependencies.resolveParticipant().id
    }

    func execute(name: String) async throws -> ParticipantDetailViewData.Member {
        do {
            let response = try await repository.addParticipant(
                eventId: eventId,
                Request(name: name, guardianId: guardianId)
            )
            return ParticipantDetailViewData.Member(id: response.id, name: response.name)
        } catch NetworkError.server(_, let reason) {
            throw AddWardError.rejected(reason)
        }
    }
}
