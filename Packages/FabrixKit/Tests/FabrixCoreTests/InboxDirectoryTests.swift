import Foundation
import Testing
@testable import FabrixCore

struct InboxDirectoryTests {
    @Test func recordedDirectoriesMapActivePeople() throws {
        let routed = try JSONDecoder().decode(UserDirectoryDTO.self, from: Data(AttentionFixtures.routedDirectory.utf8))
        let legacy = try JSONDecoder().decode(UserDirectoryDTO.self, from: Data(AttentionFixtures.legacyDirectory.utf8))
        #expect(routed.people().map(\.id) == ["routed-user-1", "routed-user-2"])
        #expect(legacy.people().map(\.id) == ["legacy-user-1"])
    }

    @Test func lenientRowsAndPrincipalIdentity() throws {
        let json = #"{"users":[{"principalId":"null-user","status":"active","user":null},{"principalId":"principal","status":"active","user":{"id":"different","name":17,"email":"ok@example.test"}},{"principalId":"inactive","status":"inactive","user":{"id":"inactive"}},{"principalId":4,"status":"active"}]}"#
        let dto = try JSONDecoder().decode(UserDirectoryDTO.self, from: Data(json.utf8))
        #expect(dto.people() == [Person(id: "null-user"), Person(id: "principal", email: "ok@example.test")])
    }

    @Test func invalidEnvelopeThrows() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(UserDirectoryDTO.self, from: Data(#"{"users":"bad"}"#.utf8))
        }
    }
}
