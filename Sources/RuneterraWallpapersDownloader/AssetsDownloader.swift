import Foundation

public final class AssetDownloader {
    private var observations = Set<NSKeyValueObservation>()
    
    private var downloadDirectory: URL?
    
    public init(downloadDirectory: URL?) {
        self.downloadDirectory = downloadDirectory
    }
        
    public func download(
        sets: Array<CardSet>,
        cardsetProgress: @escaping (CardSet, Progress) -> Void,
        completion: @escaping (Result<[URL], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var folders: Array<URL> = []
        var downloadError: Error?
        
        for set in sets {
            group.enter()
            downloadSet(
                set,
                onProgress: cardsetProgress
            ) { result in
                switch result {
                case let .success(folder):
                    folders.append(folder)
                case .failure(let error):
                    downloadError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = downloadError {
                completion(.failure(error))
            } else {
                assert(folders.count == sets.count)
                completion(.success(folders))
            }
        }
    }
    
    func downloadSet(
        _ set: CardSet,
        onProgress: @escaping (CardSet, Progress) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: set.url) { localURL, urlResponse, error in
            if let localURL = localURL {
                do {
                    let zipURL: URL
                    if let downloadURL = self.downloadDirectory {
                        zipURL = downloadURL.appendingPathComponent(set.ref).appendingPathExtension("zip")
                    } else {
                        zipURL = localURL.appendingPathExtension("zip")
                    }
                    try FileManager.default.moveItem(at: localURL, to: zipURL)
                    completion(.success(zipURL))
                } catch {
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            } else {
                assertionFailure()
            }
        }
        
        observations.insert(
            task.progress.observe(\.fractionCompleted) { progress, _ in
                onProgress(set, progress)
            }
        )
        
        task.resume()
    }
    
}





