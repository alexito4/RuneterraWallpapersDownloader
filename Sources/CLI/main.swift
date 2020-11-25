import ArgumentParser
import Foundation
import RuneterraWallpapersDownloader

struct Download: ParsableCommand {
    
    static var configuration = CommandConfiguration(commandName: "runeterraWallpaper")
    
    @Argument(help: "Directory to save the wallpapers.")
    var destination: String
    
    func run() throws {
        let downloader = AssetDownloader()
        downloader.download() { result in
            switch result {
            case .success(let urls):
                print(urls)
                for url in urls {
                    let extractor = WallpaperExtractor(
                        assetsUrl: url,
                        destinationUrl: URL(fileURLWithPath: destination)
                    )
                    extractor.extract()
                }
            case .failure(let error):
                print(error)
            }
            Darwin.exit(EXIT_SUCCESS)
        }
        
        RunLoop.main.run()
    }
    
}

Download.main()
