import ArgumentParser
import Foundation
import RuneterraWallpapersDownloader

struct Download: ParsableCommand {
    
    static var configuration = CommandConfiguration(commandName: "runeterraWallpaper")
    
    @Argument(help: "Directory to save the wallpapers.", transform: URL.init(fileURLWithPath:))
    var destination: URL
    
    @Flag(help: "If true it reads the destination folder to find the zips instead of downloading them again.")
    var skipDownload: Bool = false
    
    @Flag(help: "If true downloaded zips won't be removed. Useful if you want to use `skipDownload` later.")
    var keepZips: Bool = false
    
    func run() throws {
        let sets = CardSet.all
        
        func afterDownload(_ urls: [URL]) {
            extract(urls)
            log(sets: sets)
        }
        
        if skipDownload {
            let urls = sets
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
            afterDownload(urls)
        } else {
            download(sets, completion: afterDownload(_:))
        }
        
        RunLoop.main.run()
    }
    
    // MARK: Download
    
    private func download(_ sets: [CardSet], completion: @escaping ([URL]) -> Void) {
        print("Downloading \(sets.count) card sets:")

        let downloader = AssetDownloader(downloadDirectory: destination)

        var progressDict = Dictionary<CardSet, Progress>()

        let timer = Timer(timeInterval: 0.5, repeats: true) { timer in
            timerTick(progressDict: progressDict, timer: timer)
        }
        
        downloader.download(
            sets: sets,
            cardsetProgress: { (cardset, progress) in
                progressDict[cardset] = progress
            }
        ) { result in
            timer.invalidate()
            
            switch result {
            case .success(let urls):
                print("Downloaded.")
                completion(urls)
            case .failure(let error):
                print(error)
            }
            Darwin.exit(EXIT_SUCCESS)
        }
        
        timer.fire()
        RunLoop.main.add(timer, forMode: .default)
    }
        
    private func timerTick(progressDict: Dictionary<CardSet, Progress>, timer: Timer) {
        let maxNameLength = progressDict.keys.map(\.name.count).max() ?? 0
        let maxDescriptionLength = max(
            progressDict.values.map(\.localizedAdditionalDescription.count).max() ?? 0,
            20
        )
        
        guard timer.isValid else { return }

        var printed = 0
        for (set, progress) in progressDict.sorted(by: { $0.0.ref < $1.0.ref }) {
            let bar = progressBar(fraction: progress.fractionCompleted, length: 20)
            let percentage = "\(String(format: "%.2f", progress.fractionCompleted*100).leftpad(6))%"
            
            print("\(set.name.leftpad(maxNameLength)): \(progress.localizedAdditionalDescription?.leftpad(maxDescriptionLength) ?? "") \(bar) \(percentage)")
            
            printed += 1
        }

        guard timer.isValid else { return }
        
        eraseLines(printed)
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

Download.main()
