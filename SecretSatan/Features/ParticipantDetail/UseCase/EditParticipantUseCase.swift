import Foundation
import SecretSatanData

protocol EditParticipantUseCaseProtocol: Sendable {
    /// Renames `participant` and returns it as the backend saved it.
    func execute(name: String, of participant: ParticipantDetailViewData.Participant) async throws
        -> ParticipantDetailViewData.Participant
}

/// Changes the name of the participant through the Participants repository (`PUT /events/:id/participants/:pid`)
/// and returns only the data the screen shows, mapped out of the SecretSatanData types.
/// The `PUT` replaces every field, so it sends the phone and the guardian back unchanged.
struct EditParticipantUseCase: EditParticipantUseCaseProtocol {
    private struct Request: ParticipantsRequestProtocol {
        let name: String
        let phone: String?
        let guardianId: String?
    }

    private let repository: any ParticipantsRepositoryProtocol
    private let eventId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEventId()
    }

    func execute(name: String, of participant: ParticipantDetailViewData.Participant) async throws
        -> ParticipantDetailViewData.Participant {
        let response = try await repository.updateParticipant(
            eventId: eventId,
            participantId: participant.id,
            Request(name: name, phone: participant.phone, guardianId: participant.guardianId)
        )
        return ParticipantDetailViewData.Participant(
            id: response.id,
            name: response.name,
            initials: response.name.initials,
            phone: response.phone,
            guardianId: response.guardianId
        )
    }
}
