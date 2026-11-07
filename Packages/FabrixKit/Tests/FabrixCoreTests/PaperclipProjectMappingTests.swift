@testable import FabrixCore
import Foundation
import Testing

struct PaperclipProjectMappingTests {
    private func project(_ json: String) throws -> Project {
        try Project(paperclip: JSONDecoder().decode(ProjectDTO.self, from: Data(json.utf8)))
    }

    @Test(arguments: [
        ("backlog", ProjectStatus.backlog), ("planned", .planned), ("in_progress", .inProgress),
        ("completed", .completed), ("cancelled", .cancelled), ("paused_forever", .backlog),
    ])
    func mapsStatus(raw: String, status: ProjectStatus) throws {
        #expect(try project(#"{"id":"p","name":"P","status":"\#(raw)"}"#).status == status)
    }

    @Test func targetDateHasNoTimeZoneShift() throws {
        let date = try project(#"{"id":"p","name":"P","status":"planned","targetDate":"2026-12-15"}"#).targetDate
        #expect(date == DateComponents(year: 2026, month: 12, day: 15))
    }

    @Test func malformedTargetDateIsDropped() throws {
        #expect(try project(#"{"id":"p","name":"P","status":"planned","targetDate":"soon"}"#).targetDate == nil)
    }

    @Test func archivedFlag() throws {
        #expect(try project(#"{"id":"p","name":"P","status":"completed","archivedAt":"2026-11-07T13:40:00.000Z"}"#).isArchived)
    }

    @Test func gitRepositoryNameFallsBackToWorkspaceName() throws {
        let repo = try project(#"""
        {"id":"p","name":"P","status":"planned","workspaces":[
          {"id":"w","name":"Main repo","sourceType":"git_repo","repoUrl":"git@example.com:x.git","isPrimary":false}
        ]}
        """#).repositories.first
        #expect(repo?.kind == .git)
        #expect(repo?.name == "Main repo")
    }
}
