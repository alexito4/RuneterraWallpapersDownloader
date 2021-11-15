import Foundation
import Zip

public final class CardSets {
    
    public init() {}
    
    // https://dd.b.pvp.net/latest/core-en_us.zip
    // en_us/data/globals-en_us.json["sets"]
    public func fetchSets() async throws -> [CardSet] {
        let (localURL, _) = try await URLSession.shared.download(
            for: URLRequest(url: URL(string: "https://dd.b.pvp.net/latest/core-en_us.zip")!),
            onProgress: { _ in }
        )

        // Move temp file to zip
        let zipURL = localURL
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")
        try FileManager.default.moveItem(at: localURL, to: zipURL)
        
        // Unzip
        let destination = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sets_\(UUID().uuidString)")
        try Zip.unzipFile(zipURL, destination: destination, overwrite: true, password: nil)
        
        // Read globals file
        let globalsURL = destination
            .appendingPathComponent("en_us")
            .appendingPathComponent("data")
            .appendingPathComponent("globals-en_us")
            .appendingPathExtension("json")
        let data = try Data(contentsOf: globalsURL)
        let globals = try JSONDecoder().decode(Globals.self, from: data)
        
        let cardSets = globals.sets
            .filter {
                // Ignore the Events set. Is an only in game set,
                // all its cards belong to other sets.
                // Clarified on Discord
                // https://discord.com/channels/187652476080488449/633905002976378881/894232222146654218
                // @alexito4 the "event" set is in the client only, it doesn't exist in the API
                // For example Viego and Akshan are in this set in the client, but are in the set 4 JSON or ZIP.
                // I don't know how it will be handled in the future, but I assume that event cards are added to the latest set at the time, so you only have to worry about the numbered sets, not some "event" set
                $0.nameRef != "SetEvent"
            }
            .map(CardSet.init(set:))
        
        return cardSets
    }
}

private struct Globals: Decodable {
    let sets: [Set]
    
    struct Set: Decodable {
        public let name: String
        public let nameRef: String
    }
}

private extension CardSet {
    init(set: Globals.Set) {
        self.init(
            ref: set.nameRef,
            name: set.name,
            // URL looks like "https://dd.b.pvp.net/latest/set1-en_us.zip"
            url: URL(string: "https://dd.b.pvp.net/latest/\(set.nameRef.lowercased())-en_us.zip")!
        )
    }
}

public struct CardSet: Hashable {
    public let ref: String
    public let name: String
    public let url: URL
    
    public var number: Int {
        Int(String(ref.last!))!
    }
}

extension CardSet: CustomStringConvertible {
    public var description: String { "\(ref.last!): \(name)" }
}

extension CardSet {
    // From https://dd.b.pvp.net/latest/core-en_us.zip
    // en_us/data/globals-en_us.json["sets"]
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
        CardSet(
            ref: "Set5", // 2.14
            name: "Beyond the Bandlewood",
            url: URL(string: "https://dd.b.pvp.net/latest/set5-en_us.zip")!
        )
    ]
}
