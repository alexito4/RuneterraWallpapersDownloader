import Foundation
import Zip

public final class AssetDownloader {
    
    public init() {}
    
    private let urls: [URL] = [
        "https://dd.b.pvp.net/latest/set1-en_us.zip",
        "https://dd.b.pvp.net/latest/set2-en_us.zip",
        "https://dd.b.pvp.net/latest/set3-en_us.zip",
    ]
    .compactMap(URL.init(string:))
    
    private var observations = Set<NSKeyValueObservation>()
    
    public func download(completion: @escaping (Result<[URL], Error>) -> Void) {
        let group = DispatchGroup()
        var folders: Array<URL> = []
        var downloadError: Error?
        
        for url in urls {
            group.enter()
            downloadSet(at: url) { result in
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
                assert(folders.count == self.urls.count)
                completion(.success(folders))
            }
        }
    }
    
    func downloadSet(at url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, urlResponse, error in
            if let localURL = localURL {
                print(localURL)
                do {
                    let zipURL = localURL.appendingPathExtension("zip")
                    try FileManager.default.moveItem(at: localURL, to: zipURL)
                    let unzipDirectory = try Zip.quickUnzipFile(zipURL)
                    completion(.success(unzipDirectory))
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
                print("\(url.lastPathComponent): \(progress.fractionCompleted)")
            }
        )
        
        task.resume()
    }
    
}





