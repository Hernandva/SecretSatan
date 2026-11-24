import Contacts
import Foundation

/// On-device source of Contacts: the contacts of the device, read with the Contacts framework.
protocol ContactsStoreProtocol: Sendable {
    /// Asks for access the first time. `true` when the app can read the contacts (full or limited access).
    func requestAccess() async throws -> Bool
    /// Every contact of the device, with its name and phones as they are saved.
    func loadContacts() async throws -> [ContactsResponseDAO]
}

/// Reads the contacts with `CNContactStore`. The app needs `NSContactsUsageDescription` in its Info.plist.
struct ContactsStore: ContactsStoreProtocol {
    func requestAccess() async throws -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return try await CNContactStore().requestAccess(for: .contacts)
        @unknown default:
            return false
        }
    }

    func loadContacts() async throws -> [ContactsResponseDAO] {
        // Enumerating the contacts blocks the thread, so it runs off the caller's.
        try await Task.detached(priority: .userInitiated) {
            try Self.enumerateContacts()
        }.value
    }

    private static func enumerateContacts() throws -> [ContactsResponseDAO] {
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        var contacts: [ContactsResponseDAO] = []
        try CNContactStore().enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { contact, _ in
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            let phones = contact.phoneNumbers.map(\.value.stringValue)
            contacts.append(ContactsResponseDAO(
                id: contact.identifier,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                phones: phones
            ))
        }
        return contacts
    }
}
