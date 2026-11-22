import SecretSatanUI
import SwiftUI

/// "Participante": the name and phone of the participant selected in EventDetail, each with its edit button,
/// the participants it is the guardian of ("Protegidos") and the ones it must not be assigned ("Exclusiones").
struct ParticipantDetailView: View {
    @State private var viewModel: ParticipantDetailViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: ParticipantDetailDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .loaded:
                if let participant = viewModel.viewData.participant {
                    content(for: participant)
                }
            case .failed:
                DSText(style: .footnote, color: DSColor.destructive).localized("participantDetail.error")
            }
        }
        .sheet(isPresented: $viewModel.isEditingName) { nameSheet }
        .sheet(isPresented: $viewModel.isEditingPhone) { phoneSheet }
        .task { await viewModel.load() }
    }

    /// Sheet with the current name. "Guardar" turns active once the name changes.
    private var nameSheet: some View {
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
    private var phoneSheet: some View {
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

    @ViewBuilder
    private var editError: some View {
        if case .failed = viewModel.editState {
            DSText(style: .footnote, color: DSColor.destructive).localized("participantDetail.editError")
        }
    }

    private func content(for participant: ParticipantDetailViewData.Participant) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            header(for: participant)
            phoneCard(for: participant)
            section(
                titleKey: "participantDetail.wards",
                emptyKey: "participantDetail.wards.empty",
                addLabelKey: "participantDetail.wards.add",
                members: viewModel.viewData.wards,
                addAction: viewModel.startAddingWard
            )
            section(
                titleKey: "participantDetail.exclusions",
                emptyKey: "participantDetail.exclusions.empty",
                addLabelKey: "participantDetail.exclusions.add",
                members: viewModel.viewData.exclusions,
                addAction: viewModel.startAddingExclusion
            )
        }
    }

    /// Name of the participant with its "Editar" button.
    private func header(for participant: ParticipantDetailViewData.Participant) -> some View {
        HStack(spacing: DSSpacing.space3) {
            DSText(participant.name, style: .largeTitle)
            Spacer(minLength: 0)
            DSButton(style: .secondary, size: .compact) { viewModel.startEditingName() }
                .localized("participantDetail.edit")
                .accessibilityLabel(Text(forKey: "participantDetail.editName", value: "Edit name"))
        }
    }

    /// "Teléfono" and the number, or "Sin teléfono", with its "Editar" button.
    private func phoneCard(for participant: ParticipantDetailViewData.Participant) -> some View {
        DSListGroup {
            HStack(spacing: DSSpacing.space3) {
                VStack(alignment: .leading, spacing: 0) {
                    DSText(style: .footnote).localized("participantDetail.phone")
                    if let phone = participant.phone {
                        DSText(phone, style: .body)
                    } else {
                        DSText(style: .body, color: DSColor.textSecondary).localized("participantDetail.phone.empty")
                    }
                }
                Spacer(minLength: 0)
                DSButton(style: .secondary, size: .compact) { viewModel.startEditingPhone() }
                    .localized("participantDetail.edit")
                    .accessibilityLabel(Text(forKey: "participantDetail.editPhone", value: "Edit phone"))
            }
            .padding(.leading, DSSpacing.medium)
            .padding([.trailing, .vertical], DSSpacing.small)
        }
    }

    /// Header with its "Añadir" button and the rows of `members`, or a line saying the list is empty.
    private func section(
        titleKey: String,
        emptyKey: String,
        addLabelKey: String,
        members: [ParticipantDetailViewData.Member],
        addAction: @escaping @MainActor () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: DSSpacing.space3) {
                DSSectionHeader().localized(titleKey)
                Spacer(minLength: 0)
                DSTextButton(icon: "plus", action: addAction)
                    .localized("participantDetail.add")
                    .accessibilityLabel(Text(forKey: addLabelKey, value: "Add"))
            }
            if members.isEmpty {
                DSText(style: .body, color: DSColor.textSecondary)
                    .localized(emptyKey)
                    .padding(.horizontal, DSSpacing.medium)
            } else {
                DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                    ForEach(members) { member in
                        DSListRow(member.name, initials: member.initials)
                    }
                }
            }
        }
    }
}

#Preview {
    let participant = ParticipantDetailViewData.Participant(
        id: "preview",
        name: "Lucía Martín",
        initials: "LM",
        phone: "+34 612 345 678",
        guardianId: nil
    )
    NavigationStack {
        ParticipantDetailCoordinator(
            dependencies: ParticipantDetailDependencies(eventId: "preview", participant: participant)
        ).start()
    }
}
