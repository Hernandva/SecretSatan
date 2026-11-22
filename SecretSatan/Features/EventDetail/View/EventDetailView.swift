import SecretSatanUI
import SwiftUI

/// "Evento": the name and date of the event selected in Home, with a button to edit each, its participants and
/// the button that opens the "Nuevo participante" sheet.
struct EventDetailView: View {
    @State private var viewModel: EventDetailViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: EventDetailDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            if let event = viewModel.viewData.event {
                header(for: event)
            }

            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .loaded:
                participants
            case .failed:
                DSText(style: .footnote, color: DSColor.destructive).localized("eventDetail.error")
            }
        }
        .dsBottomBar {
            if viewModel.state == .loaded {
                DSButton(icon: .symbol("plus")) { viewModel.startAddingParticipant() }
                    .localized("eventDetail.addParticipant")
            }
        }
        .sheet(isPresented: $viewModel.isEditingName) { nameSheet }
        .sheet(isPresented: $viewModel.isEditingDate) { dateSheet }
        .sheet(isPresented: $viewModel.isAddingParticipant) { participantSheet }
        .alert(
            Text(forKey: "eventDetail.deleteError", value: "Couldn't remove the participant."),
            isPresented: $viewModel.deleteFailed
        ) {
        } message: {
            if let reason = viewModel.deleteFailureReason {
                Text(reason)
            }
        }
        .task { await viewModel.load() }
    }

    /// Name of the event and, below it, its date ("24 de diciembre de 2026"), each with its edit button.
    private func header(for event: EventDetailViewData.Event) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: DSSpacing.small) {
                DSText(event.name, style: .largeTitle)
                Spacer(minLength: 0)
                DSIconButton(systemName: "pencil") { viewModel.startEditingName() }
                    .localized("eventDetail.editName")
            }
            HStack(spacing: DSSpacing.small) {
                if let date = event.date {
                    DSText(date.formatted(date: .long, time: .omitted), style: .body, color: DSColor.textSecondary)
                } else {
                    DSText(style: .body, color: DSColor.textSecondary).localized("eventDetail.noDate")
                }
                Spacer(minLength: 0)
                DSIconButton(systemName: "calendar") { viewModel.startEditingDate() }
                    .localized("eventDetail.editDate")
            }
        }
    }

    @ViewBuilder
    private var participants: some View {
        if viewModel.viewData.participants.isEmpty {
            DSText(style: .body, color: DSColor.textSecondary).localized("eventDetail.empty")
        } else {
            VStack(alignment: .leading, spacing: DSSpacing.small) {
                DSSectionHeader().localized("eventDetail.participants")
                DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                    ForEach(viewModel.viewData.participants) { participant in
                        DSListRow(participant.name, initials: participant.initials)
                            .dsSwipeToDelete(String(localized: "eventDetail.participant.delete")) {
                                Task { await viewModel.deleteParticipant(participant) }
                            }
                    }
                }
            }
        }
    }

    /// Sheet with the current name. "Guardar" turns active once the name changes.
    private var nameSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("eventDetail.editName.title")

            DSTextField(value: $viewModel.draftName)
                .localized("eventDetail.editName.placeholder")
                .submitLabel(.done)
                .onSubmit { Task { await viewModel.saveName() } }

            editError

            Spacer(minLength: 0)

            DSButton { Task { await viewModel.saveName() } }
                .localized("eventDetail.save")
                .disabled(!viewModel.canSaveName)
        }
        .sheetLayout(isSaving: viewModel.editState == .saving)
        .presentationDetents([.medium, .large])
    }

    /// Sheet with the calendar. Picking another day saves it and closes the sheet.
    private var dateSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("eventDetail.editDate.title")

            DSCalendarPicker(date: $viewModel.draftDate)
                .disabled(viewModel.editState == .saving)
                .onChange(of: viewModel.draftDate) {
                    Task { await viewModel.saveDraftDate() }
                }

            if viewModel.editState == .saving {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            editError

            Spacer(minLength: 0)
        }
        .sheetLayout(isSaving: viewModel.editState == .saving)
        .presentationDetents([.large])
    }

    /// "Nuevo participante" sheet: name and phone, both required. "Guardar" turns active once both are filled in,
    /// adds the participant and closes the sheet.
    private var participantSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("eventDetail.newParticipant.title")

            DSTextField(value: $viewModel.participantName)
                .localized("eventDetail.newParticipant.name")
                .textContentType(.name)
                .submitLabel(.next)

            DSTextField(value: $viewModel.participantPhone)
                .localized("eventDetail.newParticipant.phone")
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)

            if case .failed(let reason) = viewModel.addParticipantState {
                if let reason {
                    DSText(reason, style: .footnote, color: DSColor.destructive)
                } else {
                    DSText(style: .footnote, color: DSColor.destructive).localized("eventDetail.newParticipant.error")
                }
            }

            Spacer(minLength: 0)

            DSButton { Task { await viewModel.saveParticipant() } }
                .localized("eventDetail.save")
                .disabled(!viewModel.canSaveParticipant)
        }
        .sheetLayout(isSaving: viewModel.addParticipantState == .saving)
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var editError: some View {
        if case .failed = viewModel.editState {
            DSText(style: .footnote, color: DSColor.destructive).localized("eventDetail.editError")
        }
    }
}

private extension View {
    /// Margins, background and drag indicator of the edit sheets, as in "Nuevo evento".
    /// The sheet can't be swiped away while the change is being saved.
    func sheetLayout(isSaving: Bool) -> some View {
        padding(.horizontal, DSSpacing.medium)
            .padding(.top, DSSpacing.large)
            .padding(.bottom, DSSpacing.small)
            .background(DSColor.background.ignoresSafeArea())
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(isSaving)
    }
}

#Preview {
    let event = EventDetailViewData.Event(id: "preview", name: "Family 2026", date: .now, participantCount: 6)
    NavigationStack {
        EventDetailCoordinator(dependencies: EventDetailDependencies(event: event)).start()
    }
}
