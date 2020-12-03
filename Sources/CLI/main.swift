import ArgumentParser
import Foundation
import RuneterraWallpapersDownloader

struct Download: ParsableCommand {
    
    static var configuration = CommandConfiguration(commandName: "runeterraWallpaper")
    
    @Argument(help: "Directory to save the wallpapers.")
    var destination: String
    
    func run() throws {
        let downloader = AssetDownloader()
        let sets = CardSet.all
        
        print("Downloading \(sets.count) card sets:")
        
        var progressDict = Dictionary<CardSet, Progress>()

        let timer = Timer(timeInterval: 0.5, repeats: true) { timer in
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
                for (i, url) in urls.enumerated() {
                    print("Extracting wallpapers \(i) of \(urls.count)")

                    let extractor = WallpaperExtractor(
                        assetsUrl: url,
                        destinationUrl: URL(fileURLWithPath: destination)
                    )
                    extractor.extract()
                }
                print("Extracted.")
            case .failure(let error):
                print(error)
            }
            Darwin.exit(EXIT_SUCCESS)
        }
        
        timer.fire()
     
        RunLoop.main.add(timer, forMode: .default)
        RunLoop.main.run()
    }
    
}

Download.main()
