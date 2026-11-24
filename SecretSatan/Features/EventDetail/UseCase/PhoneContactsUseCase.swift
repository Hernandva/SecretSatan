import Foundation
import SecretSatanData

/// Errors of `PhoneContactsUseCase` that the contacts sheet can show.
enum PhoneContactsError: Error, Equatable {
    /// The user has not allowed access to the contacts. It can be changed in Settings.
    case accessDenied
}

protocol PhoneContactsUseCaseProtocol: Sendable {
    /// Returns the phone contacts of the device, mapped into the rows of the contacts sheet.
    /// Throws `PhoneContactsError.accessDenied` when the user does not allow access to them.
    func execute() async throws -> [EventDetailViewData.Contact]
}

/// Reads the phone contacts of the device through the Contacts repository and returns only the data the sheet shows,
/// mapped out of the SecretSatanData types.
struct PhoneContactsUseCase: PhoneContactsUseCaseProtocol {
    private let repository: any ContactsRepositoryProtocol

    /// Receives only the container and resolves what it needs from it.
    /// `EventDetailDependencies` lives on the main actor, so this init does too.
    @MainActor
    init(dependencies: EventDetailDependencies) {
        self.repository = dependencies.resolveContactsRepository()
    }

    func execute() async throws -> [EventDetailViewData.Contact] {
        do {
            return try await repository.fetchContacts().compactMap(Self.contact(from:))
        } catch ContactsError.accessDenied {
            throw PhoneContactsError.accessDenied
        }
    }
}

private extension PhoneContactsUseCase {
    /// Maps one contact of the repository into a row of the sheet, with its first phone.
    static func contact(from response: any ContactsResponseProtocol) -> EventDetailViewData.Contact? {
        guard let phone = response.phones.first else { return nil }
        return EventDetailViewData.Contact(id: response.id, name: response.name, phone: phone)
    }
}
