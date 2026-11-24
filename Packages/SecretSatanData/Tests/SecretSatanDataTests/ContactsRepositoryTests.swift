import Foundation
@testable import SecretSatanData
import Testing

struct ContactsRepositoryTests {
    private struct InMemoryStore: ContactsStoreProtocol {
        let isAllowed: Bool
        let contacts: [ContactsResponseDAO]

        func requestAccess() async throws -> Bool {
            isAllowed
        }

        func loadContacts() async throws -> [ContactsResponseDAO] {
            contacts
        }
    }

    @Test func returnsContactsWithNameAndPhoneSortedByName() async throws {
        let store = InMemoryStore(isAllowed: true, contacts: [
            ContactsResponseDAO(id: "3", name: "Pablo", phones: ["600 000 003"]),
            ContactsResponseDAO(id: "1", name: "Lucía Martín", phones: ["600 000 001", "910 000 001"]),
            ContactsResponseDAO(id: "2", name: "Sin teléfono", phones: []),
            ContactsResponseDAO(id: "4", name: "", phones: ["600 000 004"])
        ])

        let contacts = try await ContactsRepository(store: store).fetchContacts()

        #expect(contacts.map(\.id) == ["1", "3"])
        #expect(contacts.first?.phones == ["600 000 001", "910 000 001"])
    }

    @Test func throwsAccessDeniedWhenTheUserRefuses() async {
        let store = InMemoryStore(isAllowed: false, contacts: [
            ContactsResponseDAO(id: "1", name: "Lucía", phones: ["600 000 001"])
        ])

        await #expect(throws: ContactsError.accessDenied) {
            try await ContactsRepository(store: store).fetchContacts()
        }
    }
}
