import FabrixCore
import Foundation
@testable import FabrixFeatures
import Testing

@MainActor
struct TaskLookupTests {
    actor MovingFactory: FactoryService {
        private let base = DemoFactoryService()
        private var moved: Set<WorkItem.ID> = []

        func move(_ id: WorkItem.ID) { moved.insert(id) }
        func companies() async throws -> [Company] { try await base.companies() }
        func snapshot(companyID: Company.ID) async throws -> CompanySnapshot {
            var snapshot = try await base.snapshot(companyID: companyID)
            for index in snapshot.tasks.indices where moved.contains(snapshot.tasks[index].id) {
                snapshot.tasks[index].status = .done
            }
            return snapshot
        }
        func decide(approvalID _: Approval.ID, approve _: Bool) async throws {}
        func wake(agentID _: Agent.ID) async throws {}
        func pause(agentID _: Agent.ID) async throws {}
        func setCompanyPaused(_: Bool, companyID _: Company.ID) async throws {}
    }

    @Test func taskLookupFollowsTheLatestSnapshot() async {
        let factory = MovingFactory()
        let model = AppModel(
            connection: FactoryConnection(factory: FactoryConnection.demo().factory, service: factory),
            defaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        await model.refresh()
        #expect(model.task("t142")?.status == .inProgress)

        await factory.move("t142")
        await model.refresh()

        #expect(model.task("t142")?.status == .done)
        #expect(model.task("missing") == nil)
    }
}

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
