import Foundation
import SecretSatanData

/// What the "Nuevo participante" sheet sends. `name` is required.
struct NewParticipantInput: Equatable, Sendable {
    let name: String
    /// `nil` when the user leaves the phone empty.
    let phone: String?
}

/// Errors of `NewParticipantUseCase` that the sheet can show.
enum NewParticipantError: Error, Equatable {
    /// The backend refused the participant, with its message, e.g. "Indica un teléfono o un tutor que reciba el enlace."
    case rejected(String)
}

protocol NewParticipantUseCaseProtocol: Sendable {
    /// Adds the participant to the event and returns it as a row of the participant list.
    /// Throws `NewParticipantError.rejected` when the backend refuses it.
    func execute(_ input: NewParticipantInput) async throws -> EventDetailViewData.Participant
}

/// Adds a participant to the selected event through the Participants repository and returns only the data the list
/// shows, mapped out of the SecretSatanData types.
struct NewParticipantUseCase: NewParticipantUseCaseProtocol {
    private struct Request: ParticipantsRequestProtocol {
        let name: String
        let phone: String?
        let guardianId: String? = nil
    }

    private let repository: any ParticipantsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `EventDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: EventDetailDependencies) {
        self.repository = dependencies.resolveParticipantsRepository()
        self.eventId = dependencies.resolveEvent().id
    }

    func execute(_ input: NewParticipantInput) async throws -> EventDetailViewData.Participant {
        do {
            let response = try await repository.addParticipant(
                eventId: eventId,
                Request(name: input.name, phone: input.phone)
            )
            return EventDetailViewData.Participant(id: response.id, name: response.name)
        } catch NetworkError.server(_, let reason) {
            throw NewParticipantError.rejected(reason)
        }
    }
}
