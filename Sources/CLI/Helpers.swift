import Foundation

extension String {
    func leftpad(_ n: Int) -> String {
        let padding = (0..<max(0, n - count)).map { _ in " " }.joined()
        return "\(padding)\(self)"
    }
}

func eraseLines(_ n: Int) {
    for _ in 0..<n {
        print("\u{001B}[1A", terminator: "") // cursor up
        print("\u{001B}[2K", terminator: "") // erase line
    }
}

func progressBar(fraction: Double, length: Int) -> String {
    let completed = String(repeating: "-", count: Int(fraction * Double(length)))
    let pending = String(repeating: " ", count: length - completed.count)
    return "[\(completed)\(pending)]"
}
