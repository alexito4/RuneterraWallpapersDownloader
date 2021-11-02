import ArgumentParser
import Foundation
import RuneterraWallpapersDownloader

struct Download: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "runeterraWallpaper")
    
    @Argument(help: "Directory to save the wallpapers.", transform: URL.init(fileURLWithPath:))
    var destination: URL
    
    @Option(name: .customLong("set"), help: "Specify all the Card Sets you want download. Use the set index. Ex: --set 1 --set 2.")
    var sets: [CardSet] = CardSet.all
    
    @Flag(help: "If true it reads the destination folder to find the zips instead of downloading them again.")
    var skipDownload: Bool = false
    
    @Flag(help: "If true downloaded zips won't be removed. Useful if you want to use `skipDownload` later.")
    var keepZips: Bool = false
        
    mutating func runAsync() async throws {
        let urls: [URL]
        if skipDownload {
            urls = sets
                .map(\.ref)
                .map {
                    destination
                        .appendingPathComponent($0)
                        .appendingPathExtension("zip")
                }
                .filter {
                    let exists = FileManager.default.fileExists(atPath: $0.path)
                    if !exists {
                        print("\($0.lastPathComponent) not found. Skipping this set.")
                    }
                    return exists
                }
        } else {
            urls = try await download(sets)
        }
        
        extract(urls)
        log(sets: sets)
    }
    
    // MARK: Download
    
    private func download(_ sets: [CardSet]) async throws -> [URL] {
        print("Downloading \(sets.count) card sets:")

        let downloader = AssetDownloader(downloadDirectory: destination)
        let progressBar = ProgressBar()
        
        let urls = try await downloader.download(
            sets: sets,
            cardsetProgress: { (cardset, progress) in
                progressBar.update(progress, for: cardset)
            }
        )
        print("Downloaded.")
        return urls
    }
        
    // MARK: Extraction
    
    private func extract(_ urls: [URL]) {
        guard urls.isEmpty == false else {
            print("Nothing to extract.")
            return
        }
        
        for (i, url) in urls.enumerated() {
            print("Extracting wallpapers \(i+1) of \(urls.count)")

            let extractor = WallpaperExtractor(
                zipUrl: url,
                destinationUrl: destination,
                removeZip: !keepZips,
                removeAssets: true
            )
            extractor.extract()
        }
        print("Extracted.")
    }
    
    // MARK: Log
    
    func log(sets: [CardSet]) {
        let imagesCount = try! FileManager.default
            .contentsOfDirectory(atPath: destination.path)
            .filter({ URL(fileURLWithPath: $0).pathExtension == "png" })
            .count
        
        let log = Log(
            date: Date(),
            sets: sets,
            numberOfWallpapers: imagesCount
        )
        
        let logLineString = log.lineString() + "\n"
        guard let logLine = logLineString.data(using: .utf8) else {
            print("Error creating log line.")
            return
        }
        let logFile = destination
            .appendingPathComponent("log")
            .appendingPathExtension("csv")
        
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logLine)
                fileHandle.closeFile()
            }
        } else {
            try? logLine.write(to: logFile, options: .atomicWrite)
        }
    }
    
}

@main
struct App {
    static func main() async {
        await Download.main()
    }
}

