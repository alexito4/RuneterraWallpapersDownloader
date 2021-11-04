import Foundation

private final class Box<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

extension URLSession {
    /// Convenience method to download using an URLRequest, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter request: The URLRequest for which to download.
    /// - Parameter onProgress: Closure to call when the progress of the task is updated.
    /// - Parameter delegate: Task-specific delegate.
    /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
    public func download(
        for request: URLRequest,
        onProgress: @escaping (Progress) -> Void,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (URL, URLResponse) {
        let observation: Box<NSKeyValueObservation?> = .init(nil)
        let urlSessionTask: Box<URLSessionTask?> = .init(nil)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let task = downloadTask(with: request) { localURL, urlResponse, error in
                    if let localURL = localURL, let response = urlResponse {
                        do {
                            // Move the file because it gets removed at the end of the completion block.
                            // I wonder how the native async variant is implemented. Do they move it or somehow keep it alive?
                            let finalPath = NSTemporaryDirectory().appending(UUID().uuidString)
                            try FileManager.default.moveItem(atPath: localURL.path, toPath: finalPath)
                            continuation.resume(returning: (URL(fileURLWithPath: finalPath), response))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        struct OtherError: Error {}
                        continuation.resume(throwing: OtherError())
                    }
                    observation.value = nil
                }
                task.delegate = delegate

                urlSessionTask.value = task
                observation.value = task.progress.observe(\.fractionCompleted) { progress, _ in
                    onProgress(progress)
                }
                
                task.resume()
            }
        } onCancel: {
            urlSessionTask.value?.cancel()
            observation.value = nil
        }
    }
}
