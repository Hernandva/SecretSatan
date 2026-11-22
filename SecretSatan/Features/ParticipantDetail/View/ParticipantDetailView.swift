import SecretSatanUI
import SwiftUI

/// "Participante": the participant selected in EventDetail, with its avatar and name.
struct ParticipantDetailView: View {
    @State private var viewModel: ParticipantDetailViewModel

    /// Receives only the container and resolves the view model from it.
    init(dependencies: ParticipantDetailDependencies) {
        _viewModel = State(initialValue: dependencies.resolveViewModel())
    }

    var body: some View {
        DSScreen {
            DSText(style: .largeTitle).localized("participantDetail.title")

            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .loaded:
                if let participant = viewModel.viewData.participant {
                    DSListGroup(separatorInset: DSListRow.iconSeparatorInset) {
                        DSListRow(participant.name, initials: participant.initials)
                    }
                }
            case .failed(let message):
                DSText(message, style: .footnote, color: DSColor.destructive)
            }
        }
        .task { await viewModel.load() }
    }
}

#Preview {
    let participant = ParticipantDetailViewData.Participant(id: "preview", name: "Lucía Martín", initials: "LM")
    NavigationStack {
        ParticipantDetailCoordinator(dependencies: ParticipantDetailDependencies(participant: participant)).start()
    }
}
