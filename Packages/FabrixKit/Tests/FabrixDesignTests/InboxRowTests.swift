@testable import FabrixDesign
import Testing

struct InboxRowTests {
    @Test func announcementIncludesContentAndStatuses() {
        #expect(InboxRow.announcement(kind: "Approval", title: "Hire a Designer agent", requester: "CEO", age: "12 minutes ago", owner: "For you", staleReason: nil, isCritical: false, isProblem: false) == "Approval. Hire a Designer agent. From CEO, 12 minutes ago. For you.")
        #expect(InboxRow.announcement(kind: "Approval", title: "Hire", requester: "CEO", age: "now", owner: "For you", staleReason: "old", isCritical: true, isProblem: true).contains("Stale: old. Critical. Problem."))
    }
}

@Test func rowAnnouncementIncludesTaskAndSummary() {
    let text = InboxRow.announcement(kind: "Approval", title: "Budget", requester: "CEO", age: "now", owner: "For you", staleReason: nil, isCritical: false, isProblem: false, taskIdentifier: "T-42", summary: "Requires finance approval")
    #expect(text.contains("T-42"))
    #expect(text.contains("Requires finance approval"))
}
