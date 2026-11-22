import Foundation

extension String {
    /// Up to two letters shown on a participant's avatar: the first letter of the first two words,
    /// uppercased. "Lucía Martín" -> "LM", "Pablo" -> "P".
    var initials: String {
        split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()
    }
}
