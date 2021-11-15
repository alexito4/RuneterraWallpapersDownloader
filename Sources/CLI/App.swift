import ArgumentParser
import Foundation
import RuneterraWallpapersDownloader

struct Download: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "runeterraWallpaper")
    
    @Argument(help: "Directory to save the wallpapers.", transform: URL.init(fileURLWithPath:))
    var destination: URL
    
    @Option(name: .customLong("set"), help: "Specify all the Card Sets you want download. Use the set reference. By default all sets will be downloaded. Ex: --set 1 --set 2.")
    var sets: [Int] = []
            
    @Flag(help: "If true it reads the destination folder to find the zips instead of downloading them again.")
    var skipDownload: Bool = false
    
    @Flag(help: "If true downloaded zips won't be removed. Useful if you want to use `skipDownload` later.")
    var keepZips: Bool = false
        
    mutating func runAsync() async throws {
        print("Fetching card sets information...")
        let fetchedSets = try await CardSets().fetchSets()
        print("\(fetchedSets.count) card sets found.")
        let setsToDownload: [CardSet]
        if sets.isEmpty {
            setsToDownload = fetchedSets
            print("Downloading all \(setsToDownload.count) available sets.")
        } else {
            setsToDownload = fetchedSets
                .filter { sets.contains($0.number) }
            
            // Inform user of sets that couldn't be found.
            if setsToDownload.count != sets.count {
                let missingSets = sets
                    .filter { number in !fetchedSets.contains { $0.number == number } }
                for set in missingSets {
                    print(">> Set \(set) not found.")
                }
            }
            
            guard setsToDownload.isEmpty == false else {
                print("Nothing to download.")
                return
            }
            
            let formatter = ListFormatter()
            formatter.locale = .init(identifier: "en_US_POSIX")
            let names = setsToDownload.map(\.name)
            let stringList = formatter.string(from: names) ?? names.joined(separator: ",")
            print("Downloading \(setsToDownload.count) requested \(setsToDownload.count > 1 ? "sets": "set"): \(stringList).")
        }
        print("")
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            let progressBar = ProgressBar()

            for `set` in setsToDownload {
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

        log(sets: setsToDownload, destination: destination)

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

