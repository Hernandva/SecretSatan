import SecretSatanUI
import SwiftUI

/// "Evento": the name of the event selected in Home, its participants and the button to add one.
struct EventDetailView: View {
    @State private var viewModel: EventDetailViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: EventDetailDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            if let event = viewModel.viewData.event {
                DSText(event.name, style: .largeTitle)
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
                // Not wired yet: the Events repository has no service to add a participant.
                DSButton(icon: .symbol("plus")) {}
                    .localized("eventDetail.addParticipant")
            }
        }
        .task { await viewModel.load() }
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
                    }
                }
            }
        }
    }
}

#Preview {
    let event = EventDetailViewData.Event(id: "preview", name: "Family 2026", date: .now, participantCount: 6)
    NavigationStack {
        EventDetailCoordinator(dependencies: EventDetailDependencies(event: event)).start()
    }
}
