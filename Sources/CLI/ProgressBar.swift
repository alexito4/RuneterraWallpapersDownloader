import Foundation
import RuneterraWallpapersDownloader

final class ProgressBar {
    var progressDict = [CardSet: Progress]()
    var lastTime = Date()

    func update(_ progress: Progress, for cardset: CardSet) {
        progressDict[cardset] = progress
        guard Date().timeIntervalSince(lastTime) > 1 else { return }
        printProgress(progressDict: progressDict)
        lastTime = Date()
    }

    private func printProgress(
        progressDict: [CardSet: Progress]
    ) {
        let maxNameLength = progressDict.keys.map(\.name.count).max() ?? 0
        let maxDescriptionLength = max(
            progressDict.values.map(\.localizedAdditionalDescription.count).max() ?? 0,
            20
        )

        var printed = 0
        for (set, progress) in progressDict.sorted(by: { $0.0.ref < $1.0.ref }) {
            let bar = progressBar(fraction: progress.fractionCompleted, length: 20)
            let percentage = "\(String(format: "%.2f", progress.fractionCompleted * 100).leftpad(6))%"

            print("\(set.name.leftpad(maxNameLength)): \(progress.localizedAdditionalDescription?.leftpad(maxDescriptionLength) ?? "") \(bar) \(percentage)")

            printed += 1
        }

        eraseLines(printed)
    }
}
