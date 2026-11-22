import Foundation
import Observation

/// State of the "Nuevo evento" sheet: the form fields and the save request.
@MainActor
@Observable
final class NewEventViewModel {
    enum State: Equatable {
        case idle
        case saving
        /// The event was created: the sheet closes.
        case saved
        case failed(String)
    }

    var name = ""
    /// `nil` until the user picks a date.
    var date: Date?
    /// Minimum price as typed, e.g. "30" or "12,50". Optional.
    var budgetText = ""

    private(set) var state: State = .idle

    private let useCase: any CreateEventUseCaseProtocol

    /// Receives only the container and resolves what it needs from it.
    init(dependencies: HomeDependencies) {
        self.useCase = dependencies.resolveCreateEventUseCase()
    }

    /// `true` when the name and the date are filled in, the minimum price is empty or a valid amount,
    /// and nothing is being saved.
    var canSave: Bool {
        input != nil && state != .saving
    }

    func save() async {
        guard let input, state != .saving else { return }
        state = .saving
        do {
            _ = try await useCase.execute(input)
            state = .saved
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// The data to send, or `nil` while the form is not valid.
    private var input: CreateEventInput? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let date else { return nil }
        switch Budget(text: budgetText) {
        case .empty:
            return CreateEventInput(name: trimmedName, date: date, budget: nil)
        case .amount(let amount):
            return CreateEventInput(name: trimmedName, date: date, budget: amount)
        case .invalid:
            return nil
        }
    }
}

/// The minimum price field, parsed.
private enum Budget {
    case empty
    case amount(Decimal)
    /// Not an amount such as "30", "30.5" or "12,50".
    case invalid

    init(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            self = .empty
        } else if trimmed.wholeMatch(of: /\d+([.,]\d{1,2})?/) != nil,
                  let amount = Decimal(string: trimmed.replacingOccurrences(of: ",", with: ".")) {
            self = .amount(amount)
        } else {
            self = .invalid
        }
    }
}
