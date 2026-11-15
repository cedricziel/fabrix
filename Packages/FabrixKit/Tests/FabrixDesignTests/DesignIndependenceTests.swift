import Foundation
import Testing

struct DesignIndependenceTests {
    @Test func noCoreImport() throws {
        let sources = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/FabrixDesign")
        let files = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" }
        #expect(!files.isEmpty)

        let importsCore = try files.filter { file in
            try String(contentsOf: file, encoding: .utf8)
                .split(separator: "\n")
                .contains { $0.contains("import") && $0.contains("FabrixCore") }
        }
        #expect(importsCore.isEmpty, "FabrixDesign must not import FabrixCore: \(importsCore.map(\.lastPathComponent))")
    }
}
