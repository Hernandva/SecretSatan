#if canImport(MessageUI)
import MessageUI
import SwiftUI

/// The system Messages composer (`MFMessageComposeViewController`) with `recipients` and `body` already filled in,
/// so the user only taps send. Show it as the content of a `.sheet`; `onFinish` runs when it is sent or cancelled,
/// to close the sheet. Check `DSMessageComposer.canSendText` first: it is `false` on the simulator and on devices
/// that can't send messages.
public struct DSMessageComposer: UIViewControllerRepresentable {
    /// `true` when the device can send SMS or iMessage.
    @MainActor public static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }

    private let recipients: [String]
    private let body: String
    private let onFinish: @MainActor () -> Void

    public init(recipients: [String], body: String, onFinish: @escaping @MainActor () -> Void) {
        self.recipients = recipients
        self.body = body
        self.onFinish = onFinish
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    public func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}

    /// Runs `onFinish` when the composer ends, whatever the result.
    @MainActor
    public final class Coordinator: NSObject, @preconcurrency MFMessageComposeViewControllerDelegate {
        private let onFinish: @MainActor () -> Void

        init(onFinish: @escaping @MainActor () -> Void) {
            self.onFinish = onFinish
        }

        public func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            onFinish()
        }
    }
}

#Preview {
    if DSMessageComposer.canSendText {
        DSMessageComposer(recipients: ["+34600333444"], body: "🎁 https://example.com") {}
    } else {
        DSText("Messages can't be sent on this device.", style: .footnote)
    }
}
#endif
