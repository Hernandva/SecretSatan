import SwiftUI

/// Month calendar to pick a day, on a rounded surface. Use it when picking the day is the whole task of the screen
/// or sheet; inside a form use `DSDatePicker`. The selected day uses the primary color.
public struct DSCalendarPicker: View {
    @Binding private var date: Date

    public init(date: Binding<Date>) {
        self._date = date
    }

    public var body: some View {
        DatePicker("", selection: $date, displayedComponents: .date)
            .datePickerStyle(.graphical)
            .labelsHidden()
            .tint(DSColor.accent)
            .padding(DSSpacing.small)
            .background(DSColor.surface, in: RoundedRectangle(cornerRadius: DSRadius.radiusGroup, style: .continuous))
    }
}

#Preview {
    @Previewable @State var date = Date()
    DSCalendarPicker(date: $date)
        .padding()
        .background(DSColor.background)
}
