// Captured 2026-11-16 at pinned commit 890dcbdd.
// Pages fetched with mine=true and limit=1; page 2 used page 1's nextCursor.
// Evidence captured after creating a dedicated in_review issue and a new strategy approval linked through issueIds.
// Keep nextCursor opaque and exactly as captured (base64 text) for preservation assertions.
extension AttentionFixtures {

    static let routedPage1 = #"""
{
  "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
  "generatedAt": "2026-11-16T17:48:06.018Z",
  "totalCount": 9,
  "deskBadgeCount": 9,
  "viewCounts": {
    "mine": 9,
    "unassigned": 0,
    "company": 1,
    "archived": 0,
    "all": 10
  },
  "nextCursor": "eyJ2IjoxLCJzb3J0IjoiYWN0aXZpdHkiLCJpZCI6ImJsb2NrZXJfYXR0ZW50aW9uOmJsb2NrZXI6YjJiNTY1NjQtZGUzNS00ZTZmLWExNmYtOTgwZDYxODc3ZDBkIn0",
  "countsBySourceKind": {
    "approval": 2,
    "decision": 0,
    "issue_thread_interaction": 5,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 2,
    "review": 0,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "blocker_attention",
      "subject": {
        "kind": "issue",
        "id": "4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Split sync worker into queue consumers",
        "identifier": "ATL-1",
        "status": "blocked",
        "href": "/ATL/issues/ATL-1",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "09c960df-defa-565c-bb15-c5066a5afa0c",
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "whyNow": "Blocks 0 tasks and needs human attention.",
      "decisionVerbs": [
        {
          "id": "unblock",
          "label": "Unblock",
          "description": "Repair or replace the stalled blocker path."
        },
        {
          "id": "reassign",
          "label": "Reassign",
          "description": "Assign the stalled blocker to a live owner."
        },
        {
          "id": "nudge",
          "label": "Nudge",
          "description": "Wake or prompt the current owner."
        }
      ],
      "inlineResolvable": false,
      "entryRule": "terminal blocker has a non-live blockerAttention.state = 'needs_attention'",
      "exitRule": "The blocking tree becomes live or no open work remains blocked.",
      "dedupKey": "blocker:4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
      "severity": "high",
      "activityAt": "2026-11-16T17:40:37.501Z",
      "createdAt": "2026-11-16T17:35:56.257Z",
      "updatedAt": "2026-11-16T17:40:37.501Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Split sync worker into queue consumers",
        "identifier": "ATL-1",
        "status": "blocked",
        "href": "/ATL/issues/ATL-1",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "09c960df-defa-565c-bb15-c5066a5afa0c",
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "blocker",
        "blockingIssue": null,
        "blockedTaskCount": 0,
        "images": []
      },
      "id": "blocker_attention:blocker:4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
      "dismissalKey": "attention:blocker:4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "be4bf8ae52b20d2e496eada4bfa1b903.me",
      "closeModes": [
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": null,
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 1
    }
  ],
  "receipts": []
}
"""#

    static let routedPage2 = #"""
{
  "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
  "generatedAt": "2026-11-16T17:48:06.187Z",
  "totalCount": 9,
  "deskBadgeCount": 9,
  "viewCounts": {
    "mine": 9,
    "unassigned": 0,
    "company": 1,
    "archived": 0,
    "all": 10
  },
  "nextCursor": "eyJ2IjoxLCJzb3J0IjoiYWN0aXZpdHkiLCJpZCI6ImFwcHJvdmFsOmFwcHJvdmFsOjllYzM2YTNmLTIxNzYtNGZiMC05ZmUzLThmYzllYTNlZjdlMiJ9",
  "countsBySourceKind": {
    "approval": 2,
    "decision": 0,
    "issue_thread_interaction": 5,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 2,
    "review": 0,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Q4 plan",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
        "metadata": {
          "type": "approve_ceo_strategy",
          "requestedByAgentId": null,
          "requestedByUserId": "routed-user-2",
          "issueId": null
        }
      },
      "whyNow": "Approval is pending a board decision.",
      "decisionVerbs": [
        {
          "id": "approve",
          "label": "Approve",
          "description": "Approve the request."
        },
        {
          "id": "reject",
          "label": "Reject",
          "description": "Reject the request."
        },
        {
          "id": "request_revision",
          "label": "Request revision",
          "description": "Send the request back for changes."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "approvals.status = 'pending'",
      "exitRule": "Approval leaves pending status.",
      "dedupKey": "approval:ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:57.650Z",
      "createdAt": "2026-11-16T17:35:57.650Z",
      "updatedAt": "2026-11-16T17:35:57.650Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "approve_ceo_strategy",
        "summaryExcerpt": "Q4 plan",
        "images": []
      },
      "id": "approval:approval:ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
      "dismissalKey": "attention:approval:ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "requester"
      },
      "stale": null,
      "required": true,
      "changeFingerprint": "7daedd7420b72bc0f3bef6f6030db16a.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 2
    }
  ],
  "receipts": []
}
"""#

    static let routedEvidence = #"""
{
  "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
  "generatedAt": "2026-11-16T18:06:19.620Z",
  "totalCount": 12,
  "deskBadgeCount": 11,
  "viewCounts": {
    "mine": 11,
    "unassigned": 0,
    "company": 1,
    "archived": 0,
    "all": 12
  },
  "nextCursor": null,
  "countsBySourceKind": {
    "approval": 3,
    "decision": 0,
    "issue_thread_interaction": 6,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 2,
    "review": 1,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "936f6794-7681-56dc-ba37-1bc8efc69856",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Evidence capture approval",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/936f6794-7681-56dc-ba37-1bc8efc69856",
        "metadata": {
          "type": "approve_ceo_strategy",
          "requestedByAgentId": null,
          "requestedByUserId": "routed-user-2",
          "issueId": "1cd22d57-3810-5451-be16-1bedeb00c4f6"
        }
      },
      "whyNow": "Approval is pending a board decision.",
      "decisionVerbs": [
        {
          "id": "approve",
          "label": "Approve",
          "description": "Approve the request."
        },
        {
          "id": "reject",
          "label": "Reject",
          "description": "Reject the request."
        },
        {
          "id": "request_revision",
          "label": "Request revision",
          "description": "Send the request back for changes."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "approvals.status = 'pending'",
      "exitRule": "Approval leaves pending status.",
      "dedupKey": "approval:936f6794-7681-56dc-ba37-1bc8efc69856",
      "severity": "medium",
      "activityAt": "2026-11-16T18:06:19.328Z",
      "createdAt": "2026-11-16T18:06:19.331Z",
      "updatedAt": "2026-11-16T18:06:19.328Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "approve_ceo_strategy",
        "summaryExcerpt": "Evidence capture approval",
        "images": []
      },
      "id": "approval:approval:936f6794-7681-56dc-ba37-1bc8efc69856",
      "dismissalKey": "attention:approval:936f6794-7681-56dc-ba37-1bc8efc69856",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "requester"
      },
      "stale": null,
      "required": true,
      "changeFingerprint": "c3afd2953d2429953590c2645070c741.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": "approval:936f6794-7681-56dc-ba37-1bc8efc69856",
      "obligationLeadId": "approval:approval:936f6794-7681-56dc-ba37-1bc8efc69856",
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 1
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "review",
      "subject": {
        "kind": "issue",
        "id": "1cd22d57-3810-5451-be16-1bedeb00c4f6",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Evidence capture review",
        "identifier": "ATL-11",
        "status": "in_review",
        "href": "/ATL/issues/ATL-11",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": null,
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "whyNow": "Issue is in review with a linked pending approval.",
      "decisionVerbs": [
        {
          "id": "approve",
          "label": "Approve",
          "description": "Approve the review and advance the issue."
        },
        {
          "id": "request_changes",
          "label": "Request changes",
          "description": "Return the issue to the assignee with changes requested."
        }
      ],
      "inlineResolvable": false,
      "entryRule": "issues.status = 'in_review' and human reviewer, user assignee, or linked pending approval exists.",
      "exitRule": "Issue leaves in_review or the human review path resolves.",
      "dedupKey": "review:1cd22d57-3810-5451-be16-1bedeb00c4f6",
      "severity": "medium",
      "activityAt": "2026-11-16T18:06:18.807Z",
      "createdAt": "2026-11-16T18:06:18.807Z",
      "updatedAt": "2026-11-16T18:06:18.807Z",
      "relatedIssue": null,
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "generic",
        "summaryExcerpt": "Evidence capture review",
        "images": []
      },
      "id": "review:review:1cd22d57-3810-5451-be16-1bedeb00c4f6",
      "dismissalKey": "attention:review:1cd22d57-3810-5451-be16-1bedeb00c4f6",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "requester"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "65b3f1464839be50640d700f940cd4d7.me",
      "closeModes": [
        "archive",
        "snooze"
      ],
      "obligationKey": "approval:936f6794-7681-56dc-ba37-1bc8efc69856",
      "obligationLeadId": "approval:approval:936f6794-7681-56dc-ba37-1bc8efc69856",
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": null,
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 2
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "a8ba24fc-ca2f-5bca-9cfc-225d3f50cd94",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Confirmation requested",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-10#interaction-a8ba24fc-ca2f-5bca-9cfc-225d3f50cd94",
        "metadata": {
          "kind": "request_confirmation",
          "issueId": "bfd929dd-6069-5725-9fc1-85acc65851c3",
          "createdByAgentId": null,
          "createdByUserId": "routed-user-2",
          "isPlanTarget": false,
          "targetDocumentKey": null,
          "requestKind": null
        }
      },
      "whyNow": "Confirmation requested on an issue thread.",
      "decisionVerbs": [
        {
          "id": "accept",
          "label": "Confirm",
          "description": "Accept the pending confirmation."
        },
        {
          "id": "reject",
          "label": "Decline",
          "description": "Decline the pending confirmation."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "issue_thread_interactions.status = 'pending'",
      "exitRule": "Interaction resolves, expires, fails, or is cancelled.",
      "dedupKey": "interaction:a8ba24fc-ca2f-5bca-9cfc-225d3f50cd94",
      "severity": "medium",
      "activityAt": "2026-11-16T17:59:16.665Z",
      "createdAt": "2026-11-16T17:58:58.965Z",
      "updatedAt": "2026-11-16T17:59:16.665Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "bfd929dd-6069-5725-9fc1-85acc65851c3",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Receipt capture confirmation",
        "identifier": "ATL-10",
        "status": "backlog",
        "href": "/ATL/issues/ATL-10",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": null,
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "confirmation",
        "promptExcerpt": "Confirm receipt capture?",
        "isPlanTarget": false,
        "images": []
      },
      "resolverAudience": {
        "requestedResolverPolicy": "anyone",
        "effectiveResolverPolicy": "anyone",
        "effectiveResolverPolicySource": "requested",
        "resolverPolicyProvenance": "inherited",
        "addresseeAgentId": null,
        "addresseeUserId": "routed-user-2",
        "addresseeName": null,
        "createdByAgentId": null,
        "createdByAgentName": null
      },
      "id": "issue_thread_interaction:interaction:a8ba24fc-ca2f-5bca-9cfc-225d3f50cd94",
      "dismissalKey": "attention:interaction:a8ba24fc-ca2f-5bca-9cfc-225d3f50cd94",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "addressee"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "822ff524968ef9052390c55ec816efc5.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "rank": 3
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "blocker_attention",
      "subject": {
        "kind": "issue",
        "id": "4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Split sync worker into queue consumers",
        "identifier": "ATL-1",
        "status": "blocked",
        "href": "/ATL/issues/ATL-1",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "09c960df-defa-565c-bb15-c5066a5afa0c",
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "whyNow": "Blocks 0 tasks and needs human attention.",
      "decisionVerbs": [
        {
          "id": "unblock",
          "label": "Unblock",
          "description": "Repair or replace the stalled blocker path."
        },
        {
          "id": "reassign",
          "label": "Reassign",
          "description": "Assign the stalled blocker to a live owner."
        },
        {
          "id": "nudge",
          "label": "Nudge",
          "description": "Wake or prompt the current owner."
        }
      ],
      "inlineResolvable": false,
      "entryRule": "terminal blocker has a non-live blockerAttention.state = 'needs_attention'",
      "exitRule": "The blocking tree becomes live or no open work remains blocked.",
      "dedupKey": "blocker:4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
      "severity": "high",
      "activityAt": "2026-11-16T17:40:37.501Z",
      "createdAt": "2026-11-16T17:35:56.257Z",
      "updatedAt": "2026-11-16T17:40:37.501Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Split sync worker into queue consumers",
        "identifier": "ATL-1",
        "status": "blocked",
        "href": "/ATL/issues/ATL-1",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "09c960df-defa-565c-bb15-c5066a5afa0c",
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "blocker",
        "blockingIssue": null,
        "blockedTaskCount": 0,
        "images": []
      },
      "id": "blocker_attention:blocker:4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
      "dismissalKey": "attention:blocker:4261bfd7-b4cc-545f-8bf1-b01a922a2dae",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "be4bf8ae52b20d2e496eada4bfa1b903.me",
      "closeModes": [
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": null,
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 4
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Q4 plan",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
        "metadata": {
          "type": "approve_ceo_strategy",
          "requestedByAgentId": null,
          "requestedByUserId": "routed-user-2",
          "issueId": null
        }
      },
      "whyNow": "Approval is pending a board decision.",
      "decisionVerbs": [
        {
          "id": "approve",
          "label": "Approve",
          "description": "Approve the request."
        },
        {
          "id": "reject",
          "label": "Reject",
          "description": "Reject the request."
        },
        {
          "id": "request_revision",
          "label": "Request revision",
          "description": "Send the request back for changes."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "approvals.status = 'pending'",
      "exitRule": "Approval leaves pending status.",
      "dedupKey": "approval:ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:57.650Z",
      "createdAt": "2026-11-16T17:35:57.650Z",
      "updatedAt": "2026-11-16T17:35:57.650Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "approve_ceo_strategy",
        "summaryExcerpt": "Q4 plan",
        "images": []
      },
      "id": "approval:approval:ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
      "dismissalKey": "attention:approval:ba03bd55-39bd-5cc5-a434-c448b0cea8ab",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "requester"
      },
      "stale": null,
      "required": true,
      "changeFingerprint": "7daedd7420b72bc0f3bef6f6030db16a.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 5
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "134413a8-d545-5e08-ab01-bccd6a66dbb8",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Product Designer",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/134413a8-d545-5e08-ab01-bccd6a66dbb8",
        "metadata": {
          "type": "hire_agent",
          "requestedByAgentId": "09c960df-defa-565c-bb15-c5066a5afa0c",
          "requestedByUserId": "routed-user-2",
          "issueId": null
        }
      },
      "whyNow": "Approval is pending a board decision.",
      "decisionVerbs": [
        {
          "id": "approve",
          "label": "Approve",
          "description": "Approve the request."
        },
        {
          "id": "reject",
          "label": "Reject",
          "description": "Reject the request."
        },
        {
          "id": "request_revision",
          "label": "Request revision",
          "description": "Send the request back for changes."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "approvals.status = 'pending'",
      "exitRule": "Approval leaves pending status.",
      "dedupKey": "approval:134413a8-d545-5e08-ab01-bccd6a66dbb8",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:57.571Z",
      "createdAt": "2026-11-16T17:35:57.572Z",
      "updatedAt": "2026-11-16T17:35:57.571Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "hire_agent",
        "summaryExcerpt": "Product Designer",
        "images": []
      },
      "id": "approval:approval:134413a8-d545-5e08-ab01-bccd6a66dbb8",
      "dismissalKey": "attention:approval:134413a8-d545-5e08-ab01-bccd6a66dbb8",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "requester"
      },
      "stale": null,
      "required": true,
      "changeFingerprint": "254f52f04dae3397e5e0ac2098ed2336.me",
      "closeModes": [
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": "CTO",
      "requester": {
        "kind": "agent",
        "id": "09c960df-defa-565c-bb15-c5066a5afa0c",
        "name": "CTO"
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 6
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "790c71bb-1ed5-56c7-a750-9b545f0de99a",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Suggested tasks need a decision",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-8#interaction-790c71bb-1ed5-56c7-a750-9b545f0de99a",
        "metadata": {
          "kind": "suggest_tasks",
          "issueId": "732db7f8-37c6-59b1-9c38-b0ab089cf0bf",
          "createdByAgentId": null,
          "createdByUserId": "routed-user-2",
          "isPlanTarget": false,
          "targetDocumentKey": null,
          "requestKind": null
        }
      },
      "whyNow": "Suggested tasks need a decision on an issue thread.",
      "decisionVerbs": [
        {
          "id": "accept",
          "label": "Accept",
          "description": "Accept the pending interaction."
        },
        {
          "id": "reject",
          "label": "Reject",
          "description": "Reject the pending interaction and provide a reason when required."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "issue_thread_interactions.status = 'pending'",
      "exitRule": "Interaction resolves, expires, fails, or is cancelled.",
      "dedupKey": "interaction:790c71bb-1ed5-56c7-a750-9b545f0de99a",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:57.252Z",
      "createdAt": "2026-11-16T17:35:57.252Z",
      "updatedAt": "2026-11-16T17:35:57.252Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "732db7f8-37c6-59b1-9c38-b0ab089cf0bf",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Suggest release task",
        "identifier": "ATL-8",
        "status": "backlog",
        "href": "/ATL/issues/ATL-8",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": null,
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "suggested_tasks",
        "taskCount": 1,
        "firstTaskTitle": "Check release readiness",
        "images": []
      },
      "resolverAudience": {
        "requestedResolverPolicy": "anyone",
        "effectiveResolverPolicy": "anyone",
        "effectiveResolverPolicySource": "requested",
        "resolverPolicyProvenance": "inherited",
        "addresseeAgentId": null,
        "addresseeUserId": null,
        "addresseeName": null,
        "createdByAgentId": null,
        "createdByAgentName": null
      },
      "id": "issue_thread_interaction:interaction:790c71bb-1ed5-56c7-a750-9b545f0de99a",
      "dismissalKey": "attention:interaction:790c71bb-1ed5-56c7-a750-9b545f0de99a",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "beced1944973339ae31bda100f5024cc.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "rank": 7
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "af7d0195-561f-51e8-8961-822d220fad01",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Item verdicts need a decision",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-7#interaction-af7d0195-561f-51e8-8961-822d220fad01",
        "metadata": {
          "kind": "request_item_verdicts",
          "issueId": "05717dd2-90da-5994-bc98-251ebbe8fb77",
          "createdByAgentId": null,
          "createdByUserId": "routed-user-2",
          "isPlanTarget": false,
          "targetDocumentKey": null,
          "requestKind": null
        }
      },
      "whyNow": "Item verdicts need a decision on an issue thread.",
      "decisionVerbs": [
        {
          "id": "accept",
          "label": "Accept",
          "description": "Accept the pending interaction."
        },
        {
          "id": "reject",
          "label": "Reject",
          "description": "Reject the pending interaction and provide a reason when required."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "issue_thread_interactions.status = 'pending'",
      "exitRule": "Interaction resolves, expires, fails, or is cancelled.",
      "dedupKey": "interaction:af7d0195-561f-51e8-8961-822d220fad01",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:57.116Z",
      "createdAt": "2026-11-16T17:35:57.116Z",
      "updatedAt": "2026-11-16T17:35:57.116Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "05717dd2-90da-5994-bc98-251ebbe8fb77",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Review release notes",
        "identifier": "ATL-7",
        "status": "backlog",
        "href": "/ATL/issues/ATL-7",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": null,
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "item_verdicts",
        "itemCount": 1,
        "promptExcerpt": "Review release notes",
        "images": []
      },
      "resolverAudience": {
        "requestedResolverPolicy": "anyone",
        "effectiveResolverPolicy": "anyone",
        "effectiveResolverPolicySource": "requested",
        "resolverPolicyProvenance": "inherited",
        "addresseeAgentId": null,
        "addresseeUserId": null,
        "addresseeName": null,
        "createdByAgentId": null,
        "createdByAgentName": null
      },
      "id": "issue_thread_interaction:interaction:af7d0195-561f-51e8-8961-822d220fad01",
      "dismissalKey": "attention:interaction:af7d0195-561f-51e8-8961-822d220fad01",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "cae9f0f2b55c9cb2591f542ba45fd8da.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "rank": 8
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "dcf8773a-7811-556b-a982-f62bf76f2ed3",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Questions need answers",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-6#interaction-dcf8773a-7811-556b-a982-f62bf76f2ed3",
        "metadata": {
          "kind": "ask_user_questions",
          "issueId": "ef3b7a33-078a-5420-a2ce-d914942168b4",
          "createdByAgentId": null,
          "createdByUserId": "routed-user-2",
          "isPlanTarget": false,
          "targetDocumentKey": null,
          "requestKind": null
        }
      },
      "whyNow": "Questions need answers on an issue thread.",
      "decisionVerbs": [
        {
          "id": "respond",
          "label": "Respond",
          "description": "Submit answers to the pending questions."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "issue_thread_interactions.status = 'pending'",
      "exitRule": "Interaction resolves, expires, fails, or is cancelled.",
      "dedupKey": "interaction:dcf8773a-7811-556b-a982-f62bf76f2ed3",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:56.955Z",
      "createdAt": "2026-11-16T17:35:56.955Z",
      "updatedAt": "2026-11-16T17:35:56.955Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "ef3b7a33-078a-5420-a2ce-d914942168b4",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Choose push provider",
        "identifier": "ATL-6",
        "status": "backlog",
        "href": "/ATL/issues/ATL-6",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": null,
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "questions",
        "questionCount": 2,
        "firstQuestionText": "Which provider?",
        "images": []
      },
      "resolverAudience": {
        "requestedResolverPolicy": "anyone",
        "effectiveResolverPolicy": "anyone",
        "effectiveResolverPolicySource": "requested",
        "resolverPolicyProvenance": "inherited",
        "addresseeAgentId": null,
        "addresseeUserId": null,
        "addresseeName": null,
        "createdByAgentId": null,
        "createdByAgentName": null
      },
      "id": "issue_thread_interaction:interaction:dcf8773a-7811-556b-a982-f62bf76f2ed3",
      "dismissalKey": "attention:interaction:dcf8773a-7811-556b-a982-f62bf76f2ed3",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "35d2716d6cfb8332987c7b20c641c0b0.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [
        {
          "key": "questions",
          "title": "Questions"
        }
      ],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "rank": 9
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "b5496ff8-f8f7-52d8-b46b-8ad4f2ab7aa2",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Selection confirmation requested",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-5#interaction-b5496ff8-f8f7-52d8-b46b-8ad4f2ab7aa2",
        "metadata": {
          "kind": "request_checkbox_confirmation",
          "issueId": "860d5038-2746-555b-892b-67e149fff509",
          "createdByAgentId": null,
          "createdByUserId": "routed-user-2",
          "isPlanTarget": false,
          "targetDocumentKey": null,
          "requestKind": null
        }
      },
      "whyNow": "Selection confirmation requested on an issue thread.",
      "decisionVerbs": [
        {
          "id": "accept",
          "label": "Accept",
          "description": "Accept the pending interaction."
        },
        {
          "id": "reject",
          "label": "Reject",
          "description": "Reject the pending interaction and provide a reason when required."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "issue_thread_interactions.status = 'pending'",
      "exitRule": "Interaction resolves, expires, fails, or is cancelled.",
      "dedupKey": "interaction:b5496ff8-f8f7-52d8-b46b-8ad4f2ab7aa2",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:56.725Z",
      "createdAt": "2026-11-16T17:35:56.725Z",
      "updatedAt": "2026-11-16T17:35:56.725Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "860d5038-2746-555b-892b-67e149fff509",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Verify readiness",
        "identifier": "ATL-5",
        "status": "backlog",
        "href": "/ATL/issues/ATL-5",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": null,
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "checkbox_confirmation",
        "optionCount": 1,
        "promptExcerpt": "Check readiness",
        "images": []
      },
      "resolverAudience": {
        "requestedResolverPolicy": "anyone",
        "effectiveResolverPolicy": "anyone",
        "effectiveResolverPolicySource": "requested",
        "resolverPolicyProvenance": "inherited",
        "addresseeAgentId": null,
        "addresseeUserId": null,
        "addresseeName": null,
        "createdByAgentId": null,
        "createdByAgentName": null
      },
      "id": "issue_thread_interaction:interaction:b5496ff8-f8f7-52d8-b46b-8ad4f2ab7aa2",
      "dismissalKey": "attention:interaction:b5496ff8-f8f7-52d8-b46b-8ad4f2ab7aa2",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "624c6fafb1f518304d3d68905e077f91.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "rank": 10
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "28468d7e-7b8d-5d48-b78b-5566df8cbd84",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Confirmation requested",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-4#interaction-28468d7e-7b8d-5d48-b78b-5566df8cbd84",
        "metadata": {
          "kind": "request_confirmation",
          "issueId": "47a1ded8-967a-5a59-ac42-5dd90ebfa9e8",
          "createdByAgentId": null,
          "createdByUserId": "routed-user-2",
          "isPlanTarget": false,
          "targetDocumentKey": null,
          "requestKind": null
        }
      },
      "whyNow": "Confirmation requested on an issue thread.",
      "decisionVerbs": [
        {
          "id": "accept",
          "label": "Proceed",
          "description": "Accept the pending confirmation."
        },
        {
          "id": "reject",
          "label": "Hold",
          "description": "Decline the pending confirmation."
        }
      ],
      "inlineResolvable": true,
      "entryRule": "issue_thread_interactions.status = 'pending'",
      "exitRule": "Interaction resolves, expires, fails, or is cancelled.",
      "dedupKey": "interaction:28468d7e-7b8d-5d48-b78b-5566df8cbd84",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:56.599Z",
      "createdAt": "2026-11-16T17:35:56.599Z",
      "updatedAt": "2026-11-16T17:35:56.599Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "47a1ded8-967a-5a59-ac42-5dd90ebfa9e8",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Confirm rollout",
        "identifier": "ATL-4",
        "status": "backlog",
        "href": "/ATL/issues/ATL-4",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": null,
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "confirmation",
        "promptExcerpt": "Proceed?",
        "isPlanTarget": false,
        "images": []
      },
      "resolverAudience": {
        "requestedResolverPolicy": "anyone",
        "effectiveResolverPolicy": "anyone",
        "effectiveResolverPolicySource": "requested",
        "resolverPolicyProvenance": "inherited",
        "addresseeAgentId": null,
        "addresseeUserId": null,
        "addresseeName": null,
        "createdByAgentId": null,
        "createdByAgentName": null
      },
      "id": "issue_thread_interaction:interaction:28468d7e-7b8d-5d48-b78b-5566df8cbd84",
      "dismissalKey": "attention:interaction:28468d7e-7b8d-5d48-b78b-5566df8cbd84",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "55b570a538e838b397916abf573e7649.me",
      "closeModes": [
        "withdraw",
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": {
        "kind": "user",
        "id": "routed-user-2",
        "name": null
      },
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "rank": 11
    },
    {
      "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
      "sourceKind": "blocker_attention",
      "subject": {
        "kind": "issue",
        "id": "5d2bfaa3-427f-56a0-84c2-8db2d2f1028d",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "fe2e39b4-1e39-538e-bfca-205ebfeadeb8",
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "whyNow": "Blocks 0 tasks and needs human attention.",
      "decisionVerbs": [
        {
          "id": "unblock",
          "label": "Unblock",
          "description": "Repair or replace the stalled blocker path."
        },
        {
          "id": "reassign",
          "label": "Reassign",
          "description": "Assign the stalled blocker to a live owner."
        },
        {
          "id": "nudge",
          "label": "Nudge",
          "description": "Wake or prompt the current owner."
        }
      ],
      "inlineResolvable": false,
      "entryRule": "terminal blocker has a non-live blockerAttention.state = 'needs_attention'",
      "exitRule": "The blocking tree becomes live or no open work remains blocked.",
      "dedupKey": "blocker:5d2bfaa3-427f-56a0-84c2-8db2d2f1028d",
      "severity": "high",
      "activityAt": "2026-11-16T17:35:56.339Z",
      "createdAt": "2026-11-16T17:35:56.339Z",
      "updatedAt": "2026-11-16T17:35:56.339Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "5d2bfaa3-427f-56a0-84c2-8db2d2f1028d",
        "companyId": "62301aef-3bbd-53b1-ab3b-37492d5882e8",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "fe2e39b4-1e39-538e-bfca-205ebfeadeb8",
          "assigneeUserId": null,
          "reviewPolicy": null
        }
      },
      "project": null,
      "workspace": null,
      "detail": {
        "kind": "blocker",
        "blockingIssue": null,
        "blockedTaskCount": 0,
        "images": []
      },
      "id": "blocker_attention:blocker:5d2bfaa3-427f-56a0-84c2-8db2d2f1028d",
      "dismissalKey": "attention:blocker:5d2bfaa3-427f-56a0-84c2-8db2d2f1028d",
      "dismissal": null,
      "audience": {
        "kind": "user",
        "userId": "routed-user-2",
        "reason": "instigator"
      },
      "stale": null,
      "required": false,
      "changeFingerprint": "be4bf8ae52b20d2e496eada4bfa1b903.me",
      "closeModes": [
        "archive",
        "snooze"
      ],
      "obligationKey": null,
      "obligationLeadId": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
      "requester": null,
      "queues": [],
      "shelf": false,
      "retentionDays": 30,
      "keep": false,
      "archivedAt": null,
      "retentionVersion": 1,
      "decideBy": null,
      "decideByAttribution": null,
      "snoozedUntil": null,
      "trainingExampleId": null,
      "resolverAudience": null,
      "rank": 12
    }
  ],
  "receipts": []
}
"""#

}
