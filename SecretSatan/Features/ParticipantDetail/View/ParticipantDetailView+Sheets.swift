import SecretSatanUI
import SwiftUI

// MARK: - Sheets

extension ParticipantDetailView {
    /// "Enviar a Bruno" sheet: who receives the link, its phone, the message and how to send it: Mensajes (only on
    /// devices that can send them), WhatsApp or "Otras apps…".
    @ViewBuilder
    var shareOptionsSheet: some View {
        if let link = viewModel.viewData.link {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                VStack(alignment: .leading, spacing: DSSpacing.xSmall) {
                    DSText(String(localized: "participantDetail.share.to \(link.recipientName)"), style: .title)
                    DSText(link.recipientPhone, style: .body, color: DSColor.textSecondary)
                }

                DSCard {
                    DSText(link.message, style: .body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)

                shareButtons(for: link)
            }
            .dsSheet()
            .presentationDetents([.medium, .large])
        }
    }

    private func shareButtons(for link: ParticipantDetailViewData.Link) -> some View {
        VStack(spacing: DSSpacing.small) {
            if DSMessageComposer.canSendText {
                DSButton(icon: .symbol("message.fill")) { viewModel.share(in: .messages) }
                    .localized("participantDetail.share.messages")
            }
            if let url = link.whatsAppURL {
                DSButton(style: .secondary, icon: .symbol("phone.bubble.fill")) {
                    openURL(url)
                    viewModel.finishSharing()
                }
                .localized("participantDetail.share.whatsApp")
            }
            DSButton(style: .outline, icon: .symbol("square.and.arrow.up")) { viewModel.share(in: .share) }
                .localized("participantDetail.share.otherApps")
        }
    }

    /// Messages composer addressed to the participant, or its guardian, with the message typed in.
    @ViewBuilder
    var messagesSheet: some View {
        if let link = viewModel.viewData.link {
            DSMessageComposer(recipients: [link.recipientPhone], body: link.message) {
                viewModel.finishSharing()
            }
            .ignoresSafeArea()
        }
    }

    /// System share sheet with the message of the link, ready to send to the participant or its guardian.
    @ViewBuilder
    var shareSheet: some View {
        if let link = viewModel.viewData.link {
            DSShareSheet(text: link.message)
                .presentationDetents([.medium, .large])
        }
    }

    /// Sheet with the current name. "Guardar" turns active once the name changes.
    var nameSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("participantDetail.editName.title")

            DSTextField(value: $viewModel.draftName)
                .localized("participantDetail.editName.placeholder")
                .textContentType(.name)
                .submitLabel(.done)
                .onSubmit { Task { await viewModel.saveName() } }

            editError

            Spacer(minLength: 0)

            DSButton { Task { await viewModel.saveName() } }
                .localized("participantDetail.save")
                .disabled(!viewModel.canSaveName)
        }
        .dsSheet(isSaving: viewModel.editState == .saving)
        .presentationDetents([.medium, .large])
    }

    /// Sheet with the current phone. "Guardar" turns active once the phone changes.
    var phoneSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("participantDetail.editPhone.title")

            DSTextField(value: $viewModel.draftPhone)
                .localized("participantDetail.editPhone.placeholder")
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)

            editError

            Spacer(minLength: 0)

            DSButton { Task { await viewModel.savePhone() } }
                .localized("participantDetail.save")
                .disabled(!viewModel.canSavePhone)
        }
        .dsSheet(isSaving: viewModel.editState == .saving)
        .presentationDetents([.medium, .large])
    }

    /// "Nuevo protegido" sheet: only the name, because a ward has no phone. "Guardar" turns active once the name is
    /// filled in, adds the participant with this participant as its guardian and closes the sheet.
    var wardSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("participantDetail.newWard.title")

            DSTextField(value: $viewModel.wardName)
                .localized("participantDetail.newWard.name")
                .textContentType(.name)
                .submitLabel(.done)
                .onSubmit { Task { await viewModel.saveWard() } }

            if case .failed(let reason) = viewModel.addWardState {
                if let reason {
                    DSText(reason, style: .footnote, color: DSColor.destructive)
                } else {
                    DSText(style: .footnote, color: DSColor.destructive).localized("participantDetail.newWard.error")
                }
            }

            Spacer(minLength: 0)

            DSButton { Task { await viewModel.saveWard() } }
                .localized("participantDetail.save")
                .disabled(!viewModel.canSaveWard)
        }
        .dsSheet(isSaving: viewModel.addWardState == .saving)
        .presentationDetents([.medium, .large])
    }
}
