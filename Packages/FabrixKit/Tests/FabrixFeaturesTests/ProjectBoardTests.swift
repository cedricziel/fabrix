import FabrixCore
@testable import FabrixFeatures
import Foundation
import Testing

struct ProjectBoardTests {
    private let at = Date(timeIntervalSince1970: 1_000_000)

    private func task(_ id: String, _ status: TaskStatus, project: String? = "p") -> WorkItem {
        WorkItem(id: id, identifier: id.uppercased(), title: id, status: status, projectID: project)
    }

    private func snapshot(tasks: [WorkItem] = [], activity: [ActivityEvent] = []) -> CompanySnapshot {
        CompanySnapshot(
            company: Company(id: "c", name: "Atlas"), agents: [Agent(id: "cto", name: "CTO", status: .running)],
            tasks: tasks, approvals: [], runs: [], activity: activity, spentMonthlyCents: 0, budgetMonthlyCents: nil,
            formerAgentIDs: ["retired"]
        )
    }

    @Test func terminatedLeadIsFormer() {
        let board = ProjectBoard(projects: [], snapshot: snapshot())
        #expect(board.lead(of: Project(id: "p", name: "P", status: .planned, leadAgentID: "retired")) == .former)
    }

    @Test func unloadedTasksBeyondTheWindow() {
        let board = ProjectBoard(projects: [], snapshot: snapshot(tasks: [task("a", .todo), task("b", .done)]))
        #expect(board.unloadedTaskCount(for: Project(id: "p", name: "P", status: .inProgress, taskCount: 5)) == 3)
        #expect(board.unloadedTaskCount(for: Project(id: "p", name: "P", status: .inProgress, taskCount: 1)) == 0)
        #expect(board.unloadedTaskCount(for: Project(id: "p", name: "P", status: .inProgress)) == 0)
    }

    @Test func countsSkipCancelled() {
        let tasks = [
            task("a", .todo), task("b", .todo), task("c", .inReview), task("d", .blocked),
            task("e", .done), task("f", .done), task("g", .done), task("h", .cancelled),
        ]
        let board = ProjectBoard(projects: [Project(id: "p", name: "P", status: .inProgress)], snapshot: snapshot(tasks: tasks))
        #expect(board.counts(for: "p") == TaskCounts(open: 3, blocked: 1, done: 3))
    }

    @Test func taskWithoutProjectCountsNowhere() {
        let board = ProjectBoard(projects: [Project(id: "p", name: "P", status: .inProgress)], snapshot: snapshot(tasks: [task("a", .todo, project: nil)]))
        #expect(board.counts(for: "p") == TaskCounts())
    }

    @Test func activityIncludesTaskAndProjectEvents() {
        let events = [
            ActivityEvent(id: "1", at: at, actor: "CTO", summary: "older task event", taskID: "a"),
            ActivityEvent(id: "2", at: at + 60, actor: "Board", summary: "project event", projectID: "p"),
            ActivityEvent(id: "3", at: at + 120, actor: "CTO", summary: "other task", taskID: "z"),
            ActivityEvent(id: "4", at: at + 180, actor: "Board", summary: "other project", projectID: "q"),
        ]
        let board = ProjectBoard(projects: [Project(id: "p", name: "P", status: .inProgress)], snapshot: snapshot(tasks: [task("a", .todo)], activity: events))
        #expect(board.activity(for: "p").map(\.id) == ["2", "1"])
    }

    @Test func leadResolution() {
        let board = ProjectBoard(projects: [], snapshot: snapshot())
        #expect(board.lead(of: Project(id: "p", name: "P", status: .planned, leadAgentID: "cto")) == .agent(Agent(id: "cto", name: "CTO", status: .running)))
        #expect(board.lead(of: Project(id: "p", name: "P", status: .planned, leadAgentID: "orbit-cto")) == .outsideCompany)
        #expect(board.lead(of: Project(id: "p", name: "P", status: .planned)) == .none)
    }

    @Test func archivedNotListedAndCompletedSplitOut() {
        let board = ProjectBoard(projects: [
            Project(id: "a", name: "A", status: .inProgress),
            Project(id: "b", name: "B", status: .completed),
            Project(id: "c", name: "C", status: .cancelled),
            Project(id: "d", name: "D", status: .planned, isArchived: true),
        ], snapshot: nil)
        #expect(board.active.map(\.id) == ["a"])
        #expect(board.completed.map(\.id) == ["b", "c"])
        #expect(board.project("d") == nil)
    }
}
