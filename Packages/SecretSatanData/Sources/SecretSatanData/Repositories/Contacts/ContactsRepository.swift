import Foundation

/// Public API of the Contacts repository. Features depend on this protocol, never on the concrete class.
public protocol ContactsRepositoryProtocol: Sendable {
    /// Asks for access to the contacts the first time, then returns every contact that has a name and at least one
    /// phone, sorted by name. Throws `ContactsError.accessDenied` when the user does not allow it.
    func fetchContacts() async throws -> [any ContactsResponseProtocol]
}

/// Reads the phone contacts of the device, through `Local/ContactsStore`. It only reads: it never saves or changes
/// a contact.
/// Flow: ContactsStore (Contacts framework) -> ContactsResponseDAO -> ContactsResponseProtocol.
public final class ContactsRepository: ContactsRepositoryProtocol {
    private let store: any ContactsStoreProtocol

    public init() {
        store = ContactsStore()
    }

    /// Lets tests inject another store.
    init(store: any ContactsStoreProtocol) {
        self.store = store
    }

    public func fetchContacts() async throws -> [any ContactsResponseProtocol] {
        guard try await store.requestAccess() else {
            throw ContactsError.accessDenied
        }
        return try await store.loadContacts()
            .filter { !$0.name.isEmpty && !$0.phones.isEmpty }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
