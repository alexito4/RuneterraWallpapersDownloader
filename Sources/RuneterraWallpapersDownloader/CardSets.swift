import Foundation

public struct CardSet: Hashable {
    public let ref: String
    public let name: String
    public let url: URL
}

extension CardSet: CustomStringConvertible {
    public var description: String { "\(ref.last!): \(name)" }
}

extension CardSet {
    public static let all = [
        CardSet(
            ref: "Set1", // 1.0
            name: "Foundations",
            url: URL(string: "https://dd.b.pvp.net/latest/set1-en_us.zip")!
        ),
        CardSet(
            ref: "Set2", // 1.0
            name: "Rising Tides",
            url: URL(string: "https://dd.b.pvp.net/latest/set2-en_us.zip")!
        ),
        CardSet(
            ref: "Set3", // 1.8
            name: "Call of the Mountain",
            url: URL(string: "https://dd.b.pvp.net/latest/set3-en_us.zip")!
        ),
        CardSet(
            ref: "Set4", // 2.3
            name: "Empires of the Ascended",
            url: URL(string: "https://dd.b.pvp.net/latest/set4-en_us.zip")!
        ),
    ]
}
