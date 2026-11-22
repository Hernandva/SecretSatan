import SwiftUI

public extension View {
    /// Margins, background and drag indicator of a bottom sheet with a form, e.g. the one that edits a name.
    /// While `isSaving` is `true` the sheet can't be swiped away, so the change being saved is not lost.
    ///
    ///     .sheet(isPresented: $isEditing) {
    ///         VStack { … }
    ///             .dsSheet(isSaving: isSaving)
    ///             .presentationDetents([.medium, .large])
    ///     }
    func dsSheet(isSaving: Bool = false) -> some View {
        padding(.horizontal, DSSpacing.medium)
            .padding(.top, DSSpacing.large)
            .padding(.bottom, DSSpacing.small)
            .background(DSColor.background.ignoresSafeArea())
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(isSaving)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            VStack(alignment: .leading, spacing: DSSpacing.medium) {
                DSText("Event name", style: .title)
                DSTextField(value: .constant("Family 2026"))
                Spacer(minLength: 0)
                DSButton("Save") {}
            }
            .dsSheet()
            .presentationDetents([.medium])
        }
}
