import SecretSatanUI
import SwiftUI

// MARK: - Contacts sheet

extension EventDetailView {
    /// "Contactos" sheet: the phone contacts that are not participants yet, a search bar that filters them and
    /// rows that pick several. "Añadir" adds the picked ones; "Añadir otros" opens the "Nuevo participante" sheet.
    var contactsSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("eventDetail.contacts.title")

            if viewModel.contactsState == .loaded {
                DSSearchField(query: $viewModel.contactsQuery)
                    .localized("eventDetail.contacts.search")
            }

            contactsContent
                .frame(maxHeight: .infinity, alignment: .top)

            contactsError

            contactsButtons
        }
        .dsSheet(isSaving: viewModel.addContactsState == .saving)
        .presentationDetents([.large])
        .task { await viewModel.loadContacts() }
    }
}

private extension EventDetailView {
    /// The list of contacts, or a line for the loading, empty, denied and failed states.
    @ViewBuilder
    var contactsContent: some View {
        switch viewModel.contactsState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
        case .denied:
            contactsDenied
        case .failed:
            DSText(style: .footnote, color: DSColor.destructive).localized("eventDetail.contacts.error")
        case .loaded:
            let contacts = viewModel.visibleContacts
            if contacts.isEmpty {
                DSText(style: .body, color: DSColor.textSecondary).localized(
                    viewModel.contactsQuery.isEmpty ? "eventDetail.contacts.empty" : "eventDetail.contacts.noResults"
                )
            } else {
                ScrollView {
                    DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                        ForEach(contacts) { contact in
                            contactRow(contact)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    /// Row that picks or unpicks the contact.
    func contactRow(_ contact: EventDetailViewData.Contact) -> some View {
        Button {
            viewModel.toggleContact(contact)
        } label: {
            DSListRow(
                contact.name,
                subtitle: contact.phone,
                initials: contact.initials,
                isSelected: viewModel.selectedContactIds.contains(contact.id)
            )
        }
        .buttonStyle(.plain)
    }

    /// Line saying the app can't read the contacts, with a button that opens the app's page in Settings.
    var contactsDenied: some View {
        VStack(alignment: .leading, spacing: DSSpacing.small) {
            DSText(style: .body, color: DSColor.textSecondary).localized("eventDetail.contacts.denied")
            DSButton(style: .secondary, size: .compact) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .localized("eventDetail.contacts.openSettings")
        }
    }

    @ViewBuilder
    var contactsError: some View {
        if case .failed(let reason) = viewModel.addContactsState {
            if let reason {
                DSText(reason, style: .footnote, color: DSColor.destructive)
            } else {
                DSText(style: .footnote, color: DSColor.destructive).localized("eventDetail.contacts.addError")
            }
        }
    }

    /// "Añadir" while nothing is picked, then "Añadir 2" with the number of picked contacts.
    var addContactsTitle: String {
        let count = viewModel.selectedContactIds.count
        guard count > 0 else { return String(localized: "eventDetail.add") }
        return String(localized: "eventDetail.contacts.add \(count)")
    }

    /// "Añadir (n)", active once a contact is picked, and "Añadir otros".
    var contactsButtons: some View {
        VStack(spacing: DSSpacing.small) {
            DSButton(addContactsTitle) {
                Task { await viewModel.addSelectedContacts() }
            }
            .disabled(!viewModel.canAddContacts)

            DSButton(style: .secondary, icon: .symbol("person.badge.plus")) {
                viewModel.startAddingOtherParticipant()
            }
            .localized("eventDetail.contacts.addOthers")
            .disabled(viewModel.addContactsState == .saving)
        }
    }
}
