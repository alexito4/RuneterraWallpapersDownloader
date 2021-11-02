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
    
    func downloadSet(
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

extension URLSession {
    /// Convenience method to download using an URLRequest, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to download.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
    public func download(
        for request: URLRequest,
        onProgress: @escaping (Progress) -> Void,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (URL, URLResponse) {
        var observation: NSKeyValueObservation?
        return try await withCheckedThrowingContinuation { continuation in
            let task = downloadTask(with: request) { localURL, urlResponse, error in
                if let localURL = localURL, let response = urlResponse {
                    continuation.resume(returning: (localURL, response))
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    struct OtherError: Error {}
                    continuation.resume(throwing: OtherError())
                }
                observation = nil
                
                _ = observation // to remove "never read" warning
            }
            task.delegate = delegate
            
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                onProgress(progress)
            }
            
            task.resume()
        }
        // TODO: How to use withTaskCancellationHandler to cancel the task
    }
}


