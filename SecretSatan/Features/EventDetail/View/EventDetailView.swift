import SecretSatanUI
import SwiftUI

/// "Evento": the name and date of the event selected in Home, with a button to edit each, and its participants,
/// whose "Añadir" button opens the contacts sheet, and from it the "Nuevo participante" sheet.
struct EventDetailView: View {
    @State var viewModel: EventDetailViewModel
    @Environment(\.openURL) var openURL

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
                drawBar
            }
        }
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .editName: nameSheet
            case .editDate: dateSheet
            case .newParticipant: participantSheet
            case .contacts: contactsSheet
            }
        }
        .alert(
            Text(forKey: "eventDetail.deleteError", value: "Couldn't remove the participant."),
            isPresented: $viewModel.deleteFailed
        ) {
        } message: {
            if let reason = viewModel.deleteFailureReason {
                Text(reason)
            }
        }
        .alert(
            Text(forKey: "eventDetail.draw.confirm.title", value: "Draw names?"),
            isPresented: $viewModel.drawConfirmationShown
        ) {
            Button(role: .cancel) {
            } label: {
                Text(forKey: "eventDetail.draw.confirm.cancel", value: "Cancel")
            }
            Button {
                Task { await viewModel.draw() }
            } label: {
                Text(forKey: "eventDetail.draw", value: "Draw names")
            }
        } message: {
            Text(
                forKey: "eventDetail.draw.confirm.message",
                value: "Once the names are drawn, the draw can't be undone."
            )
        }
        .alert(
            Text(forKey: "eventDetail.draw.error", value: "Couldn't make the draw."),
            isPresented: $viewModel.drawFailed
        ) {
        } message: {
            if let reason = viewModel.drawFailureReason {
                Text(reason)
            }
        }
        .task { await viewModel.load() }
    }

    /// "Sortear", active from `minimumParticipantsToDraw` participants, with a line saying how many are missing.
    /// Once the event is drawn, only a line saying so, with the number of assignments when it was drawn here.
    @ViewBuilder
    private var drawBar: some View {
        if viewModel.isDrawn {
            if let draw = viewModel.viewData.draw {
                DSText(String(localized: "eventDetail.draw.done \(draw.assignments)"), style: .footnote)
            } else {
                DSText(style: .footnote).localized("eventDetail.draw.alreadyDone")
            }
        } else {
            if !viewModel.hasEnoughParticipantsToDraw {
                DSText(
                    String(localized: "eventDetail.draw.notEnough \(EventDetailViewModel.minimumParticipantsToDraw)"),
                    style: .footnote,
                    color: DSColor.textSecondary
                )
            }
            DSButton(icon: .symbol("shuffle")) { viewModel.startDrawing() }
                .localized("eventDetail.draw")
                .disabled(!viewModel.canDraw)
        }
    }

    /// "Participantes" header with its "Añadir" button and the rows of the participants, or a line saying the list
    /// is empty.
    private var participants: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: DSSpacing.space3) {
                DSSectionHeader().localized("eventDetail.participants")
                Spacer(minLength: 0)
                if viewModel.canChangeParticipants {
                    DSTextButton(icon: "plus", action: viewModel.startAddingParticipant)
                        .localized("eventDetail.add")
                        .accessibilityLabel(Text(forKey: "eventDetail.addParticipant", value: "Add participant"))
                }
            }
            if viewModel.viewData.participants.isEmpty {
                DSText(style: .body, color: DSColor.textSecondary)
                    .localized("eventDetail.empty")
                    .padding(.horizontal, DSSpacing.medium)
            } else {
                DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                    ForEach(viewModel.viewData.participants) { participant in
                        if viewModel.canChangeParticipants {
                            participantRow(participant)
                                .dsSwipeToDelete(String(localized: "eventDetail.participant.delete")) {
                                    Task { await viewModel.deleteParticipant(participant) }
                                }
                        } else {
                            participantRow(participant)
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
        .dsSheet(isSaving: viewModel.editState == .saving)
        .presentationDetents([.medium, .large])
    }

    /// Sheet with the calendar on the current date. "Guardar" turns active once another day is picked.
    private var dateSheet: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("eventDetail.editDate.title")

            DSCalendarPicker(date: $viewModel.draftDate)
                .disabled(viewModel.editState == .saving)

            editError

            Spacer(minLength: 0)

            DSButton { Task { await viewModel.saveDate() } }
                .localized("eventDetail.save")
                .disabled(!viewModel.canSaveDate)
        }
        .dsSheet(isSaving: viewModel.editState == .saving)
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
        .dsSheet(isSaving: viewModel.addParticipantState == .saving)
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var editError: some View {
        if case .failed = viewModel.editState {
            DSText(style: .footnote, color: DSColor.destructive).localized("eventDetail.editError")
        }
    }
}

private extension EventDetailView {
    /// Name of the event and, below it, its date ("24 de diciembre de 2026"), each with its edit button.
    func header(for event: EventDetailViewData.Event) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.small) {
            HStack(spacing: DSSpacing.space3) {
                DSText(event.name, style: .largeTitle)
                Spacer(minLength: 0)
                DSButton(style: .secondary, size: .compact) { viewModel.startEditingName() }
                    .localized("eventDetail.edit")
                    .accessibilityLabel(Text(forKey: "eventDetail.editName", value: "Edit name"))
            }
            HStack(spacing: DSSpacing.space3) {
                if let date = event.date {
                    DSText(date.formatted(date: .long, time: .omitted), style: .body, color: DSColor.textSecondary)
                } else {
                    DSText(style: .body, color: DSColor.textSecondary).localized("eventDetail.noDate")
                }
                Spacer(minLength: 0)
                DSButton(style: .secondary, size: .compact) { viewModel.startEditingDate() }
                    .localized("eventDetail.edit")
                    .accessibilityLabel(Text(forKey: "eventDetail.editDate", value: "Edit date"))
            }
        }
    }

    /// Row that opens the participant's detail.
    func participantRow(_ participant: EventDetailViewData.Participant) -> some View {
        let route = EventDetailCoordinator.Route.participantDetail(participant, isDrawn: viewModel.isDrawn)
        return NavigationLink(value: route) {
            DSListRow(participant.name, initials: participant.initials, showsChevron: true)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let event = EventDetailViewData.Event(
        id: "preview",
        name: "Family 2026",
        date: .now,
        participantCount: 6,
        isDrawn: false
    )
    NavigationStack {
        EventDetailCoordinator(dependencies: EventDetailDependencies(event: event)).start()
    }
}
