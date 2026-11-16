// Captured 2026-11-16 from upstream 890dcbdd pinned image: board A transferred B-owned confirmation to A; response fetched as B, with one transferred receipt.
extension AttentionFixtures {
    static let routedReceipt = #"""
{
  "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
  "generatedAt": "2026-11-16T17:59:16.898Z",
  "totalCount": 0,
  "deskBadgeCount": 0,
  "viewCounts": {
    "mine": 0,
    "unassigned": 0,
    "company": 1,
    "archived": 0,
    "all": 10
  },
  "nextCursor": null,
  "countsBySourceKind": {
    "approval": 0,
    "decision": 0,
    "issue_thread_interaction": 0,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 0,
    "review": 0,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [],
  "receipts": [
    {
      "id": "0a13143d-5f6a-5968-b0be-35befe3dc646",
      "dismissalKey": "attention:receipt:0a13143d-5f6a-5968-b0be-35befe3dc646",
      "outcome": "transferred",
      "sourceKind": "issue_thread_interaction",
      "sourceId": "a8ba24fc-ca2f-5bca-9cfc-225d3f50cd94",
      "title": "Confirmation requested",
      "reason": "Sandbox receipt capture return",
      "actorUserId": "routed-user-2",
      "transferredToUserId": "routed-user-2",
      "issue": {
        "id": "bfd929dd-6069-5725-9fc1-85acc65851c3",
        "identifier": "ATL-10",
        "title": "Receipt capture confirmation",
        "href": "/ATL/issues/ATL-10"
      },
      "href": "/ATL/issues/ATL-10#interaction-a8ba24fc-ca2f-5bca-9cfc-225d3f50cd94",
      "createdAt": "2026-11-16T17:59:16.670Z",
      "expiresAt": "2026-11-23T17:59:16.670Z"
    }
  ]
}
"""#
}
