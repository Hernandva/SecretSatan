import SecretSatanUI
import SwiftUI

/// "Nuevo evento" sheet: name and date (required) and minimum price (optional). "Guardar" turns active once the
/// required fields are filled in, creates the event and closes the sheet.
struct NewEventView: View {
    @State private var viewModel: NewEventViewModel
    @Environment(\.dismiss) private var dismiss

    /// Receives only the container and resolves the view model from it.
    init(dependencies: HomeDependencies) {
        _viewModel = State(initialValue: dependencies.resolveNewEventViewModel())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.medium) {
            DSText(style: .title).localized("home.newEvent.title")

            DSTextField(value: $viewModel.name)
                .localized("home.newEvent.name")
                .submitLabel(.next)

            DSDatePicker(date: $viewModel.date, placeholder: String(localized: "home.newEvent.date.choose"))
                .localized("home.newEvent.date")

            DSTextField(value: $viewModel.budgetText)
                .localized("home.newEvent.budget")
                .keyboardType(.decimalPad)

            if case .failed = viewModel.state {
                DSText(style: .footnote, color: DSColor.destructive).localized("home.newEvent.error")
            }

            Spacer(minLength: 0)

            DSButton { Task { await viewModel.save() } }
                .localized("home.newEvent.save")
                .disabled(!viewModel.canSave)
        }
        .padding(.horizontal, DSSpacing.medium)
        .padding(.top, DSSpacing.large)
        .padding(.bottom, DSSpacing.small)
        .background(DSColor.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.state == .saving)
        .onChange(of: viewModel.state) { _, state in
            if state == .saved { dismiss() }
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        NewEventView(dependencies: HomeDependencies())
    }
}
