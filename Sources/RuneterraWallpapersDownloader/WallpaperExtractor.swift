import Foundation
import Zip

public struct WallpaperExtractor {
    private let zipUrl: URL
    private let destinationUrl: URL
    private let removeZip: Bool
    private let removeAssets: Bool
    
    public init(zipUrl: URL, destinationUrl: URL, removeZip: Bool, removeAssets: Bool) {
        self.zipUrl = zipUrl
        self.destinationUrl = destinationUrl
        self.removeZip = removeZip
        self.removeAssets = removeAssets
    }
    
    private let fm = FileManager.default
    
    public func extract() {
        let assetsUrl = destinationUrl
            .appendingPathComponent(zipUrl.lastPathComponent)
            .deletingPathExtension()
        do {
            try Zip.unzipFile(zipUrl, destination: assetsUrl, overwrite: true, password: nil)
        } catch {
            print(error)
            return
        }
        
        let langFolder = assetsUrl.appendingPathComponent("en_us", isDirectory: true)
        let imgFolder = langFolder.appendingPathComponent("img", isDirectory: true)
        let cardsFolder = imgFolder.appendingPathComponent("cards", isDirectory: true)
        
        let files = try! fm.contentsOfDirectory(at: cardsFolder, includingPropertiesForKeys: nil, options: [])
        let filtered = files
            .filter(isWallpaper(_:))
        for file in filtered {
            let target = destinationUrl.appendingPathComponent(file.lastPathComponent)
            tryPrint {
                if fm.fileExists(atPath: target.path) {
                    print("Skipping \(target.lastPathComponent). It already exists.")
                } else {
                    try fm.copyItem(at: file, to: target)
                }
            }
        }
        
        if removeZip {
            tryPrint {
                try fm.removeItem(at: zipUrl)
            }
        }
        if removeAssets {
            tryPrint {
                try fm.removeItem(at: assetsUrl)
            }
        }
    }
    
    private func isWallpaper(_ url: URL) -> Bool {
        if url.lastPathComponent.contains("full"),
           let size = imageDimensions(url),
           size.width != size.height
        {
            return true
        } else {
            return false
        }
    }
    
    private func imageDimensions(_ url: URL) -> CGSize? {
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?
        {
            
            let width = imageProperties[kCGImagePropertyPixelWidth] as! Int
            let height = imageProperties[kCGImagePropertyPixelHeight] as! Int
            
            return CGSize(width: width, height: height)
        } else {
            return nil
        }
    }
}

func tryPrint(_ f: () throws -> Void) {
    do {
        try f()
    } catch {
//        print(error)
    }
}
