import Foundation
import Testing

struct DesignIndependenceTests {
    @Test func noCoreImport() throws {
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/FabrixDesign")
        let files = try #require(FileManager.default.enumerator(at: source, includingPropertiesForKeys: nil))
        for case let file as URL in files where file.pathExtension == "swift" {
            let contents = try String(contentsOf: file, encoding: .utf8)
            #expect(!contents.contains("import FabrixCore"), "Core import found in \(file.lastPathComponent)")
        }
    }
}
