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
            return ParticipantDetailViewData.Link(
                message: response.message,
                recipientName: response.deliverToName,
                recipientPhone: response.deliverToPhone,
                whatsAppURL: Self.whatsAppURL(phone: response.deliverToPhone, message: response.message)
            )
        } catch NetworkError.server(_, let reason) {
            throw ShareLinkError.rejected(reason)
        }
    }
}

extension ShareLinkUseCase {
    /// `https://wa.me/<number>?text=<message>`, with the number in international format and only digits:
    /// "+34 600 333 444" -> "34600333444". The message is percent-encoded except for unreserved characters, so a
    /// "+" or "&" in it is sent as it is.
    static func whatsAppURL(phone: String, message: String) -> URL? {
        let number = phone.filter(\.isWholeNumber)
        let unreserved = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        )
        guard !number.isEmpty, let text = message.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            return nil
        }
        return URL(string: "https://wa.me/\(number)?text=\(text)")
    }
}
