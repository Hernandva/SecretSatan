import SecretSatanUI
import SwiftUI

/// Detail of the event selected in the list of Home: its name, date and participants.
struct EventDetailView: View {
    @State private var viewModel: EventDetailViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: EventDetailDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .loaded:
                if let event = viewModel.viewData.event {
                    content(for: event)
                }
            case .failed:
                DSText(style: .footnote, color: DSColor.destructive).localized("eventDetail.error")
            }
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func content(for event: EventDetailViewData.Event) -> some View {
        DSText(event.name, style: .largeTitle)

        DSSectionHeader().localized("eventDetail.details")
        DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
            DSListRow(
                dateText(for: event),
                subtitle: String(localized: "eventDetail.date"),
                icon: "calendar"
            )
            DSListRow(
                String(localized: "eventDetail.participants \(event.participantCount)"),
                subtitle: String(localized: "eventDetail.participantsLabel"),
                icon: "person.2"
            )
        }
    }

    /// "12 dic 2026", or "No date" when the event has none.
    private func dateText(for event: EventDetailViewData.Event) -> String {
        guard let date = event.date else { return String(localized: "eventDetail.noDate") }
        return date.formatted(date: .long, time: .omitted)
    }
}

#Preview {
    let event = EventDetailViewData.Event(id: "preview", name: "Family 2026", date: .now, participantCount: 6)
    NavigationStack {
        EventDetailCoordinator(dependencies: EventDetailDependencies(event: event)).start()
    }
}
