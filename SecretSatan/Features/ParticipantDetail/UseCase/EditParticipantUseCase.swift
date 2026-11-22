import Foundation
import SecretSatanData

/// One change the user makes to the participant from ParticipantDetail.
enum EditParticipantChange: Equatable, Sendable {
    case name(String)
    case phone(String)
}

protocol EditParticipantUseCaseProtocol: Sendable {
    /// Saves the change to `participant` and returns it as the backend saved it.
    func execute(_ change: EditParticipantChange, of participant: ParticipantDetailViewData.Participant) async throws
        -> ParticipantDetailViewData.Participant
}

/// Changes the name or the phone of the participant through the Participants repository (`PUT /events/:id/participants/:pid`)
/// and returns only the data the screen shows, mapped out of the SecretSatanData types.
/// The `PUT` replaces every field, so it sends the fields that don't change back as they are.
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

    func execute(_ change: EditParticipantChange, of participant: ParticipantDetailViewData.Participant) async throws
        -> ParticipantDetailViewData.Participant {
        let response = try await repository.updateParticipant(
            eventId: eventId,
            participantId: participant.id,
            Self.request(for: change, of: participant)
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

private extension EditParticipantUseCase {
    /// Every field of the participant, with the one that changes replaced.
    private static func request(
        for change: EditParticipantChange,
        of participant: ParticipantDetailViewData.Participant
    ) -> Request {
        switch change {
        case .name(let name):
            Request(name: name, phone: participant.phone, guardianId: participant.guardianId)
        case .phone(let phone):
            Request(name: participant.name, phone: phone, guardianId: participant.guardianId)
        }
    }
}
