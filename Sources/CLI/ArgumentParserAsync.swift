import ArgumentParser

@available(macOS 12.0, *)
protocol AsyncParsableCommand: ParsableCommand {
    mutating func runAsync() async throws
}

extension ParsableCommand {
    static func main(_ arguments: [String]? = nil) async {
        do {
            var command = try parseAsRoot(arguments)
            if #available(macOS 12.0, *), var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.runAsync()
            } else {
                try command.run()
            }
        } catch {
            print(error)
            exit(withError: error)
        }
    }
}
