import SecretSatanUI
import SwiftUI

/// "Participante": the name and phone of the participant selected in EventDetail, each with its edit button,
/// the participants it is the guardian of ("Protegidos") and the ones it must not be assigned ("Exclusiones").
/// A participant with a guardian shows only its name and "Exclusiones".
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
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .editName: nameSheet
            case .editPhone: phoneSheet
            case .newWard: wardSheet
            case .newExclusion: exclusionSheet
            }
        }
        .alert(deleteFailureTitle, isPresented: $viewModel.deleteFailed) {
        } message: {
            if let reason = viewModel.deleteFailure?.reason {
                Text(reason)
            }
        }
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

    /// "Nuevo protegido" sheet: only the name, because a ward has no phone. "Guardar" turns active once the name is
    /// filled in, adds the participant with this participant as its guardian and closes the sheet.
    private var wardSheet: some View {
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

    /// "Nueva exclusión" sheet: the participants of the event that can be excluded. Picking one saves the exclusion,
    /// adds it to "Exclusiones" and closes the sheet.
    private var exclusionSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("participantDetail.newExclusion.title")

            switch viewModel.candidatesState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .failed:
                DSText(style: .footnote, color: DSColor.destructive).localized("participantDetail.newExclusion.error")
            case .loaded:
                addExclusionError
                exclusionCandidates
                    .disabled(viewModel.addExclusionState == .saving)
            }

            Spacer(minLength: 0)
        }
        .dsSheet(isSaving: viewModel.addExclusionState == .saving)
        .presentationDetents([.medium, .large])
        .task { await viewModel.loadExclusionCandidates() }
    }

    @ViewBuilder
    private var exclusionCandidates: some View {
        if viewModel.viewData.exclusionCandidates.isEmpty {
            DSText(style: .body, color: DSColor.textSecondary).localized("participantDetail.newExclusion.empty")
        } else {
            ScrollView {
                DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                    ForEach(viewModel.viewData.exclusionCandidates) { candidate in
                        Button {
                            Task { await viewModel.selectExclusionCandidate(candidate) }
                        } label: {
                            DSListRow(candidate.name, initials: candidate.initials)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var addExclusionError: some View {
        if case .failed(let reason) = viewModel.addExclusionState {
            if let reason {
                DSText(reason, style: .footnote, color: DSColor.destructive)
            } else {
                DSText(style: .footnote, color: DSColor.destructive)
                    .localized("participantDetail.newExclusion.saveError")
            }
        }
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
            // A ward has no phone of its own and can't have wards: its guardian receives its link.
            if !participant.hasGuardian {
                phoneCard(for: participant)
                section(
                    .wards,
                    members: viewModel.viewData.wards,
                    addAction: viewModel.startAddingWard,
                    deleteAction: { ward in Task { await viewModel.deleteWard(ward) } }
                )
            }
            section(
                .exclusions,
                members: viewModel.viewData.exclusions,
                addAction: viewModel.startAddingExclusion,
                deleteAction: { excluded in Task { await viewModel.deleteExclusion(excluded) } }
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
        _ texts: ListSection,
        members: [ParticipantDetailViewData.Member],
        addAction: @escaping @MainActor () -> Void,
        deleteAction: @escaping @MainActor (ParticipantDetailViewData.Member) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: DSSpacing.space3) {
                DSSectionHeader().localized(texts.titleKey)
                Spacer(minLength: 0)
                DSTextButton(icon: "plus", action: addAction)
                    .localized("participantDetail.add")
                    .accessibilityLabel(Text(forKey: texts.addLabelKey, value: "Add"))
            }
            if members.isEmpty {
                DSText(style: .body, color: DSColor.textSecondary)
                    .localized(texts.emptyKey)
                    .padding(.horizontal, DSSpacing.medium)
            } else {
                DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                    ForEach(members) { member in
                        DSListRow(member.name, initials: member.initials)
                            .dsSwipeToDelete(texts.deleteLabel) { deleteAction(member) }
                    }
                }
            }
        }
    }

    /// Alert shown when removing a ward or an exclusion fails, with the backend's reason when it gave one.
    private var deleteFailureTitle: Text {
        switch viewModel.deleteFailure {
        case .exclusion:
            Text(forKey: "participantDetail.exclusions.deleteError", value: "Couldn't remove the exclusion.")
        case .ward, nil:
            Text(forKey: "participantDetail.wards.deleteError", value: "Couldn't remove the dependent.")
        }
    }
}

/// Texts of a "Protegidos" or "Exclusiones" section.
private struct ListSection {
    let titleKey: String
    let emptyKey: String
    /// Accessibility label of its "Añadir" button.
    let addLabelKey: String
    /// Title of the button revealed by swiping a row, already localised.
    let deleteLabel: String

    static let wards = ListSection(
        titleKey: "participantDetail.wards",
        emptyKey: "participantDetail.wards.empty",
        addLabelKey: "participantDetail.wards.add",
        deleteLabel: String(localized: "participantDetail.delete")
    )

    static let exclusions = ListSection(
        titleKey: "participantDetail.exclusions",
        emptyKey: "participantDetail.exclusions.empty",
        addLabelKey: "participantDetail.exclusions.add",
        deleteLabel: String(localized: "participantDetail.delete")
    )
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
