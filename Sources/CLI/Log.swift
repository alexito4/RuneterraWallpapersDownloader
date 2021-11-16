import Foundation
import RuneterraWallpapersDownloader

struct Log {
    let date: Date
    let sets: [CardSet]
    let numberOfWallpapers: Int
}

extension Log {
    func lineString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateString = dateFormatter.string(from: date)

        let setsString = sets
            .map(\.ref)
            .joined(separator: "-")

        return "\(dateString),\(setsString),\(numberOfWallpapers)"
    }
}
