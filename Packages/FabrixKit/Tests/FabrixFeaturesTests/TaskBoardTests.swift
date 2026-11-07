import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

struct TaskBoardTests {
    private func task(_ id: String, _ status: TaskStatus, updated: TimeInterval = 0) -> WorkItem {
        WorkItem(id: id, identifier: id, title: id, status: status, updatedAt: Date(timeIntervalSinceReferenceDate: updated))
    }

    @Test func boardHasOneColumnPerWorkflowStatusInOrder() {
        let columns = TaskBoard.columns(for: [task("a", .done)])
        #expect(columns.map(\.status) == [.backlog, .todo, .inProgress, .inReview, .blocked, .done])
    }

    @Test func boardPutsEachTaskInItsStatusColumnNewestFirst() {
        let columns = TaskBoard.columns(for: [
            task("old", .todo, updated: 1), task("new", .todo, updated: 5), task("x", .blocked),
        ])
        #expect(columns.first { $0.status == .todo }?.tasks.map(\.id) == ["new", "old"])
        #expect(columns.first { $0.status == .blocked }?.tasks.map(\.id) == ["x"])
    }

    @Test func boardHidesCancelledTasks() {
        let columns = TaskBoard.columns(for: [task("c", .cancelled)])
        #expect(columns.allSatisfy { $0.tasks.isEmpty })
    }

    @Test func compactSectionsSkipEmptyStatuses() {
        let sections = TaskBoard.sections(for: [task("a", .done), task("b", .inProgress)])
        #expect(sections.map(\.status) == [.inProgress, .done])
    }
}
