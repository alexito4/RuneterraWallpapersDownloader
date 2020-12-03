import Foundation

public struct WallpaperExtractor {
    let assetsUrl: URL
    let destinationUrl: URL
    
    public init(assetsUrl: URL, destinationUrl: URL) {
        self.assetsUrl = assetsUrl
        self.destinationUrl = destinationUrl
    }
    
    let fm = FileManager.default
    
    public func extract() {
        let langFolder = assetsUrl.appendingPathComponent("en_us", isDirectory: true)
        let imgFolder = langFolder.appendingPathComponent("img", isDirectory: true)
        let cardsFolder = imgFolder.appendingPathComponent("cards", isDirectory: true)
        
        let files = try! fm.contentsOfDirectory(at: cardsFolder, includingPropertiesForKeys: nil, options: [])
        let filtered = files
            .filter(isWallpaper(_:))
        for file in filtered {
            let target = destinationUrl.appendingPathComponent(file.lastPathComponent)
            tryPrint {
                try fm.copyItem(at: file, to: target)
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
        print(error)
    }
}
