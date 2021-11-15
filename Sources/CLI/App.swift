import ArgumentParser
import Foundation
import RuneterraWallpapersDownloader

struct Download: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "runeterraWallpaper")
    
    @Argument(help: "Directory to save the wallpapers.", transform: URL.init(fileURLWithPath:))
    var destination: URL
    
    @Option(name: .customLong("set"), help: "Specify all the Card Sets you want download. Use the set index. Ex: --set 1 --set 2.")
    var sets: [CardSet] = CardSet.all
    
    @Flag(help: "EXPERIMENTAL - Fetch card sets from Riot's API.")
    var fetchSets: Bool = false
    
    @Option(help: "EXPERIMENTAL - IDs of the sets to download.")
    var fsets: [Int] = []
    
    @Flag(help: "If true it reads the destination folder to find the zips instead of downloading them again.")
    var skipDownload: Bool = false
    
    @Flag(help: "If true downloaded zips won't be removed. Useful if you want to use `skipDownload` later.")
    var keepZips: Bool = false
        
    mutating func runAsync() async throws {
        if fetchSets {
            print("Fetching card sets information...")
            let fetchedSets = try await CardSets().fetchSets()
            print("\(fetchedSets.count) card sets found.")
            let setsToDownload: [CardSet]
            if fsets.isEmpty {
                setsToDownload = fetchedSets
                print("Downloading all available sets")
            } else {
                setsToDownload = fetchedSets
                    .filter { fsets.contains($0.number) }
                if setsToDownload.count != fsets.count {
                    let missingSets = fsets
                        .filter { number in !fetchedSets.contains { $0.number == number } }
                    print(">> Sets [\(missingSets.map(String.init).joined(separator: ","))] not found.")
                }
                print("Downloading requested sets")
            }
            dump(setsToDownload)
            return
        }
        
        print("Downloading \(sets.count) card sets:")

        try await withThrowingTaskGroup(of: Void.self) { group in
            let progressBar = ProgressBar()

            for `set` in sets {
                let ifNeeded = !skipDownload
                let destination = destination
                let keepZips = keepZips
                group.addTask {
                    let url = try await download(set, ifNeeded: ifNeeded, destination: destination, progressBar: progressBar)
                    await extract(url, destination: destination, keepZips: keepZips)
                }
            }

            try await group.waitForAll()
        }

        log(sets: sets, destination: destination)

        print("Downloaded.")
    }
}

// MARK: Download

/// Downloads the zip or just returns the file URL for an existing downlaoded file.
private func download(
    _ set: CardSet,
    ifNeeded: Bool,
    destination: URL,
    progressBar: ProgressBar
) async throws -> URL {
    if ifNeeded {
        return try await download(set, destination: destination, progressBar: progressBar)
    } else {
        let zipUrl = destination
            .appendingPathComponent(set.ref)
            .appendingPathExtension("zip")
        
        let exists = FileManager.default.fileExists(atPath: zipUrl.path)
        if !exists {
            print("\(zipUrl.lastPathComponent) not found. Skipping this set.")
        }
        return zipUrl
    }
}

private func download(
    _ set: CardSet,
    destination: URL,
    progressBar: ProgressBar
) async throws -> URL {
    let downloader = AssetDownloader(downloadDirectory: destination)
    return try await downloader.downloadSet(set) { set, progress in
        progressBar.update(progress, for: set)
    }
}
        
// MARK: Extraction

private func extract(_ url: URL, destination: URL, keepZips: Bool) async {
    let extractor = WallpaperExtractor(
        zipUrl: url,
        destinationUrl: destination,
        removeZip: !keepZips,
        removeAssets: true
    )
    extractor.extract()
}

// MARK: Log

func log(sets: [CardSet], destination: URL) {
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

@main
struct App {
    static func main() async {
        await Download.main()
    }
}

