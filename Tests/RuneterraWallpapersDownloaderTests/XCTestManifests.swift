import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(RuneterraWallpapersDownloaderTests.allTests),
        ]
    }
#endif
