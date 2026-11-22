import Foundation
import SecretSatanData

/// Errors of `ShareLinkUseCase` that the screen can show.
enum ShareLinkError: Error, Equatable {
    /// The backend refused to create the link, with its message, e.g. before the draw.
    case rejected(String)
}

protocol ShareLinkUseCaseProtocol: Sendable {
    /// Returns a new link of the participant to share. The view model adds it to its `ParticipantDetailViewData`.
    /// Throws `ShareLinkError.rejected` when the backend refuses.
    func execute() async throws -> ParticipantDetailViewData.Link
}

/// Asks the Participants repository for a new link of the selected participant, to send it again.
struct ShareLinkUseCase: ShareLinkUseCaseProtocol {
    private let repository: any ParticipantsRepositoryProtocol
    private let eventId: String
    private let participantId: String

    /// Receives only the container and resolves what it needs from it.
    /// `ParticipantDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: ParticipantDetailDependencies) {
        self.repository = dependencies.resolveRepository()
        self.eventId = dependencies.resolveEventId()
        self.participantId = dependencies.resolveParticipant().id
    }

    func execute() async throws -> ParticipantDetailViewData.Link {
        do {
            let response = try await repository.fetchLink(eventId: eventId, participantId: participantId)
            return ParticipantDetailViewData.Link(message: response.message)
        } catch NetworkError.server(_, let reason) {
            throw ShareLinkError.rejected(reason)
        }
    }
}
