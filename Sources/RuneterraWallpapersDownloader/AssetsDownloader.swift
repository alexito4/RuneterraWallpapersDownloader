import Foundation

public final class AssetDownloader {
    private var downloadDirectory: URL?
    
    public init(downloadDirectory: URL?) {
        self.downloadDirectory = downloadDirectory
    }
    
    public func download(
        sets: Array<CardSet>,
        cardsetProgress: @escaping (CardSet, Progress) -> Void
    ) async throws -> [URL] {
        return try await withThrowingTaskGroup(of: URL.self, returning: [URL].self, body: { group in
            for set in sets {
                _ = group.addTaskUnlessCancelled {
                    try await self.downloadSet(
                        set,
                        onProgress: cardsetProgress
                    )
                }
            }

            let folders = try await group.reduce(into: [], { $0.append($1) })
            assert(folders.count == sets.count)
            return folders
        })
    }
    
    public func downloadSet(
        _ set: CardSet,
        onProgress: @escaping (CardSet, Progress) -> Void
    ) async throws -> URL {
        let (localURL, _) = try await URLSession.shared.download(
            for: URLRequest(url: set.url),
            onProgress: { onProgress(set, $0) }
        )
        let zipURL: URL
        if let downloadURL = self.downloadDirectory {
            zipURL = downloadURL.appendingPathComponent(set.ref).appendingPathExtension("zip")
        } else {
            zipURL = localURL.appendingPathExtension("zip")
        }
        try FileManager.default.moveItem(at: localURL, to: zipURL)
        return zipURL
    }
}
