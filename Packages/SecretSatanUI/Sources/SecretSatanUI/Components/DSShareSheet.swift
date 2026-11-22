#if canImport(UIKit)
import SwiftUI
import UIKit

/// The system share sheet (`UIActivityViewController`) with `text`, to send it by Messages, WhatsApp, Mail…
/// Show it as the content of a `.sheet` and add `.presentationDetents([.medium, .large])` beside it.
/// The text is already localised: it is sent as it is.
public struct DSShareSheet: UIViewControllerRepresentable {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    public func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DSShareSheet(text: "🎁 https://example.com")
                .presentationDetents([.medium, .large])
        }
}
#endif
