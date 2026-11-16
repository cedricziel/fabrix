/// Recorded Paperclip attention inbox responses. UUIDs and email addresses are sanitized.
enum AttentionFixtures {
    static let legacyMine = #"""
{
  "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
  "generatedAt": "2026-11-16T17:21:17.811Z",
  "totalCount": 3,
  "deskBadgeCount": 3,
  "nextCursor": null,
  "countsBySourceKind": {
    "approval": 2,
    "decision": 0,
    "issue_thread_interaction": 0,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 1,
    "review": 0,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [
    {
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "845af1d1-667d-5817-b971-8dc0889b06aa",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Q4 plan",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/845af1d1-667d-5817-b971-8dc0889b06aa",
        "metadata": {
          "type": "approve_ceo_strategy",
          "requestedByAgentId": null,
          "requestedByUserId": "legacy-user-1",
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
      "dedupKey": "approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "severity": "medium",
      "activityAt": "2026-11-16T17:21:06.326Z",
      "createdAt": "2026-11-16T17:21:06.327Z",
      "updatedAt": "2026-11-16T17:21:06.326Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "approve_ceo_strategy",
        "summaryExcerpt": "Q4 plan",
        "images": []
      },
      "id": "approval:approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "dismissalKey": "attention:approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "dismissal": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
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
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "44f9955f-79d9-58df-bf32-595b1822968e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Product Designer",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/44f9955f-79d9-58df-bf32-595b1822968e",
        "metadata": {
          "type": "hire_agent",
          "requestedByAgentId": "f2ca5527-e529-5958-ac9e-b411fc1d4647",
          "requestedByUserId": "legacy-user-1",
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
      "dedupKey": "approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "severity": "medium",
      "activityAt": "2026-11-16T17:21:06.281Z",
      "createdAt": "2026-11-16T17:21:06.284Z",
      "updatedAt": "2026-11-16T17:21:06.281Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "hire_agent",
        "summaryExcerpt": "Product Designer",
        "images": []
      },
      "id": "approval:approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "dismissalKey": "attention:approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "dismissal": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": "CTO",
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
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "blocker_attention",
      "subject": {
        "kind": "issue",
        "id": "c17fc627-e997-56e7-972f-04c7a571024e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "e9b1b343-58f4-5820-81ce-30962b6af5f7",
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
      "dedupKey": "blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "severity": "high",
      "activityAt": "2026-11-16T17:21:05.571Z",
      "createdAt": "2026-11-16T17:21:05.571Z",
      "updatedAt": "2026-11-16T17:21:05.571Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "c17fc627-e997-56e7-972f-04c7a571024e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "e9b1b343-58f4-5820-81ce-30962b6af5f7",
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
      "id": "blocker_attention:blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "dismissalKey": "attention:blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "dismissal": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
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
      "rank": 3
    }
  ]
}
"""#

    static let legacyUnassigned = #"""
{
  "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
  "generatedAt": "2026-11-16T17:21:17.848Z",
  "totalCount": 3,
  "deskBadgeCount": 3,
  "nextCursor": null,
  "countsBySourceKind": {
    "approval": 2,
    "decision": 0,
    "issue_thread_interaction": 0,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 1,
    "review": 0,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [
    {
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "845af1d1-667d-5817-b971-8dc0889b06aa",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Q4 plan",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/845af1d1-667d-5817-b971-8dc0889b06aa",
        "metadata": {
          "type": "approve_ceo_strategy",
          "requestedByAgentId": null,
          "requestedByUserId": "legacy-user-1",
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
      "dedupKey": "approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "severity": "medium",
      "activityAt": "2026-11-16T17:21:06.326Z",
      "createdAt": "2026-11-16T17:21:06.327Z",
      "updatedAt": "2026-11-16T17:21:06.326Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "approve_ceo_strategy",
        "summaryExcerpt": "Q4 plan",
        "images": []
      },
      "id": "approval:approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "dismissalKey": "attention:approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "dismissal": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
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
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "44f9955f-79d9-58df-bf32-595b1822968e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Product Designer",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/44f9955f-79d9-58df-bf32-595b1822968e",
        "metadata": {
          "type": "hire_agent",
          "requestedByAgentId": "f2ca5527-e529-5958-ac9e-b411fc1d4647",
          "requestedByUserId": "legacy-user-1",
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
      "dedupKey": "approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "severity": "medium",
      "activityAt": "2026-11-16T17:21:06.281Z",
      "createdAt": "2026-11-16T17:21:06.284Z",
      "updatedAt": "2026-11-16T17:21:06.281Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "hire_agent",
        "summaryExcerpt": "Product Designer",
        "images": []
      },
      "id": "approval:approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "dismissalKey": "attention:approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "dismissal": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": "CTO",
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
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "blocker_attention",
      "subject": {
        "kind": "issue",
        "id": "c17fc627-e997-56e7-972f-04c7a571024e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "e9b1b343-58f4-5820-81ce-30962b6af5f7",
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
      "dedupKey": "blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "severity": "high",
      "activityAt": "2026-11-16T17:21:05.571Z",
      "createdAt": "2026-11-16T17:21:05.571Z",
      "updatedAt": "2026-11-16T17:21:05.571Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "c17fc627-e997-56e7-972f-04c7a571024e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "e9b1b343-58f4-5820-81ce-30962b6af5f7",
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
      "id": "blocker_attention:blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "dismissalKey": "attention:blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "dismissal": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
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
      "rank": 3
    }
  ]
}
"""#

    static let legacyCompany = #"""
{
  "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
  "generatedAt": "2026-11-16T17:21:17.886Z",
  "totalCount": 3,
  "deskBadgeCount": 3,
  "nextCursor": null,
  "countsBySourceKind": {
    "approval": 2,
    "decision": 0,
    "issue_thread_interaction": 0,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 1,
    "review": 0,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [
    {
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "845af1d1-667d-5817-b971-8dc0889b06aa",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Q4 plan",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/845af1d1-667d-5817-b971-8dc0889b06aa",
        "metadata": {
          "type": "approve_ceo_strategy",
          "requestedByAgentId": null,
          "requestedByUserId": "legacy-user-1",
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
      "dedupKey": "approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "severity": "medium",
      "activityAt": "2026-11-16T17:21:06.326Z",
      "createdAt": "2026-11-16T17:21:06.327Z",
      "updatedAt": "2026-11-16T17:21:06.326Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "approve_ceo_strategy",
        "summaryExcerpt": "Q4 plan",
        "images": []
      },
      "id": "approval:approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "dismissalKey": "attention:approval:845af1d1-667d-5817-b971-8dc0889b06aa",
      "dismissal": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
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
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "44f9955f-79d9-58df-bf32-595b1822968e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Product Designer",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/44f9955f-79d9-58df-bf32-595b1822968e",
        "metadata": {
          "type": "hire_agent",
          "requestedByAgentId": "f2ca5527-e529-5958-ac9e-b411fc1d4647",
          "requestedByUserId": "legacy-user-1",
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
      "dedupKey": "approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "severity": "medium",
      "activityAt": "2026-11-16T17:21:06.281Z",
      "createdAt": "2026-11-16T17:21:06.284Z",
      "updatedAt": "2026-11-16T17:21:06.281Z",
      "relatedIssue": null,
      "detail": {
        "kind": "approval",
        "approvalType": "hire_agent",
        "summaryExcerpt": "Product Designer",
        "images": []
      },
      "id": "approval:approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "dismissalKey": "attention:approval:44f9955f-79d9-58df-bf32-595b1822968e",
      "dismissal": null,
      "project": null,
      "workspace": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": "CTO",
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
      "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
      "sourceKind": "blocker_attention",
      "subject": {
        "kind": "issue",
        "id": "c17fc627-e997-56e7-972f-04c7a571024e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "e9b1b343-58f4-5820-81ce-30962b6af5f7",
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
      "dedupKey": "blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "severity": "high",
      "activityAt": "2026-11-16T17:21:05.571Z",
      "createdAt": "2026-11-16T17:21:05.571Z",
      "updatedAt": "2026-11-16T17:21:05.571Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "c17fc627-e997-56e7-972f-04c7a571024e",
        "companyId": "ce82b71a-49a5-505f-8c51-0303ec4f72e3",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "e9b1b343-58f4-5820-81ce-30962b6af5f7",
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
      "id": "blocker_attention:blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "dismissalKey": "attention:blocker:c17fc627-e997-56e7-972f-04c7a571024e",
      "dismissal": null,
      "expiresAt": null,
      "ruleKey": null,
      "originAgentName": null,
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
      "rank": 3
    }
  ]
}
"""#

    static let legacyDirectory = #"""
{
  "users": [
    {
      "principalId": "legacy-user-1",
      "status": "active",
      "user": {
        "id": "legacy-user-1",
        "email": "user@example.test",
        "name": "Sandbox Board",
        "image": null
      }
    }
  ]
}
"""#

    static let routedMine = #"""
{
  "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
  "generatedAt": "2026-11-16T17:36:07.417Z",
  "totalCount": 8,
  "deskBadgeCount": 8,
  "viewCounts": {
    "mine": 8,
    "unassigned": 0,
    "company": 0,
    "archived": 0,
    "all": 8
  },
  "nextCursor": null,
  "countsBySourceKind": {
    "approval": 2,
    "decision": 0,
    "issue_thread_interaction": 5,
    "join_request": 0,
    "recovery_action": 0,
    "productivity_review": 0,
    "blocker_attention": 1,
    "review": 0,
    "failed_run": 0,
    "budget_alert": 0,
    "agent_error_alert": 0
  },
  "items": [
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "1dc6f132-3ac9-501b-b20b-62383f961795",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Q4 plan",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/1dc6f132-3ac9-501b-b20b-62383f961795",
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
      "dedupKey": "approval:1dc6f132-3ac9-501b-b20b-62383f961795",
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
      "id": "approval:approval:1dc6f132-3ac9-501b-b20b-62383f961795",
      "dismissalKey": "attention:approval:1dc6f132-3ac9-501b-b20b-62383f961795",
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
      "rank": 1
    },
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "approval",
      "subject": {
        "kind": "approval",
        "id": "d469c821-1ae3-586a-9a44-f5b61154295e",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Product Designer",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/approvals/d469c821-1ae3-586a-9a44-f5b61154295e",
        "metadata": {
          "type": "hire_agent",
          "requestedByAgentId": "e733c358-c8d1-57a8-a905-8e210e1e4860",
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
      "dedupKey": "approval:d469c821-1ae3-586a-9a44-f5b61154295e",
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
      "id": "approval:approval:d469c821-1ae3-586a-9a44-f5b61154295e",
      "dismissalKey": "attention:approval:d469c821-1ae3-586a-9a44-f5b61154295e",
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
        "id": "e733c358-c8d1-57a8-a905-8e210e1e4860",
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
      "rank": 2
    },
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "ac8ee625-7918-5530-9d2f-1ac07fb46411",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Suggested tasks need a decision",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-8#interaction-ac8ee625-7918-5530-9d2f-1ac07fb46411",
        "metadata": {
          "kind": "suggest_tasks",
          "issueId": "e286d5e4-1509-5a53-8a37-37ef3a4dc5d4",
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
      "dedupKey": "interaction:ac8ee625-7918-5530-9d2f-1ac07fb46411",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:57.252Z",
      "createdAt": "2026-11-16T17:35:57.252Z",
      "updatedAt": "2026-11-16T17:35:57.252Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "e286d5e4-1509-5a53-8a37-37ef3a4dc5d4",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
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
      "id": "issue_thread_interaction:interaction:ac8ee625-7918-5530-9d2f-1ac07fb46411",
      "dismissalKey": "attention:interaction:ac8ee625-7918-5530-9d2f-1ac07fb46411",
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
      "rank": 3
    },
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "fbe9378b-510e-56a2-8cb0-5860647b4343",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Item verdicts need a decision",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-7#interaction-fbe9378b-510e-56a2-8cb0-5860647b4343",
        "metadata": {
          "kind": "request_item_verdicts",
          "issueId": "3f8c350e-9ad7-5635-a085-9e60ce33d82d",
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
      "dedupKey": "interaction:fbe9378b-510e-56a2-8cb0-5860647b4343",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:57.116Z",
      "createdAt": "2026-11-16T17:35:57.116Z",
      "updatedAt": "2026-11-16T17:35:57.116Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "3f8c350e-9ad7-5635-a085-9e60ce33d82d",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
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
      "id": "issue_thread_interaction:interaction:fbe9378b-510e-56a2-8cb0-5860647b4343",
      "dismissalKey": "attention:interaction:fbe9378b-510e-56a2-8cb0-5860647b4343",
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
      "rank": 4
    },
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "2308bf8f-ea3a-50cd-a2af-fd235fffda8b",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Questions need answers",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-6#interaction-2308bf8f-ea3a-50cd-a2af-fd235fffda8b",
        "metadata": {
          "kind": "ask_user_questions",
          "issueId": "95243552-a5bd-5a30-8add-8872a3690a94",
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
      "dedupKey": "interaction:2308bf8f-ea3a-50cd-a2af-fd235fffda8b",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:56.955Z",
      "createdAt": "2026-11-16T17:35:56.955Z",
      "updatedAt": "2026-11-16T17:35:56.955Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "95243552-a5bd-5a30-8add-8872a3690a94",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
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
      "id": "issue_thread_interaction:interaction:2308bf8f-ea3a-50cd-a2af-fd235fffda8b",
      "dismissalKey": "attention:interaction:2308bf8f-ea3a-50cd-a2af-fd235fffda8b",
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
      "rank": 5
    },
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "e05f3f9e-aa77-5f42-95c8-c32c707916d6",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Selection confirmation requested",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-5#interaction-e05f3f9e-aa77-5f42-95c8-c32c707916d6",
        "metadata": {
          "kind": "request_checkbox_confirmation",
          "issueId": "06173ed2-733f-5a4d-8d16-a24061784110",
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
      "dedupKey": "interaction:e05f3f9e-aa77-5f42-95c8-c32c707916d6",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:56.725Z",
      "createdAt": "2026-11-16T17:35:56.725Z",
      "updatedAt": "2026-11-16T17:35:56.725Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "06173ed2-733f-5a4d-8d16-a24061784110",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
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
      "id": "issue_thread_interaction:interaction:e05f3f9e-aa77-5f42-95c8-c32c707916d6",
      "dismissalKey": "attention:interaction:e05f3f9e-aa77-5f42-95c8-c32c707916d6",
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
      "rank": 6
    },
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "issue_thread_interaction",
      "subject": {
        "kind": "interaction",
        "id": "4b3d6695-81c1-55e6-a588-48cb71a7b0a9",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Confirmation requested",
        "identifier": null,
        "status": "pending",
        "href": "/ATL/issues/ATL-4#interaction-4b3d6695-81c1-55e6-a588-48cb71a7b0a9",
        "metadata": {
          "kind": "request_confirmation",
          "issueId": "466d4058-a40d-5b5c-8a64-b2c175bfac26",
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
      "dedupKey": "interaction:4b3d6695-81c1-55e6-a588-48cb71a7b0a9",
      "severity": "medium",
      "activityAt": "2026-11-16T17:35:56.599Z",
      "createdAt": "2026-11-16T17:35:56.599Z",
      "updatedAt": "2026-11-16T17:35:56.599Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "466d4058-a40d-5b5c-8a64-b2c175bfac26",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
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
      "id": "issue_thread_interaction:interaction:4b3d6695-81c1-55e6-a588-48cb71a7b0a9",
      "dismissalKey": "attention:interaction:4b3d6695-81c1-55e6-a588-48cb71a7b0a9",
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
      "rank": 7
    },
    {
      "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
      "sourceKind": "blocker_attention",
      "subject": {
        "kind": "issue",
        "id": "07feb67b-25b6-587c-9f42-8b9b6a2013e8",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "75b082d5-00d6-5304-b603-cbeb35c40d00",
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
      "dedupKey": "blocker:07feb67b-25b6-587c-9f42-8b9b6a2013e8",
      "severity": "high",
      "activityAt": "2026-11-16T17:35:56.339Z",
      "createdAt": "2026-11-16T17:35:56.339Z",
      "updatedAt": "2026-11-16T17:35:56.339Z",
      "relatedIssue": {
        "kind": "issue",
        "id": "07feb67b-25b6-587c-9f42-8b9b6a2013e8",
        "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
        "title": "Rotate staging certificates",
        "identifier": "ATL-2",
        "status": "blocked",
        "href": "/ATL/issues/ATL-2",
        "metadata": {
          "priority": "medium",
          "assigneeAgentId": "75b082d5-00d6-5304-b603-cbeb35c40d00",
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
      "id": "blocker_attention:blocker:07feb67b-25b6-587c-9f42-8b9b6a2013e8",
      "dismissalKey": "attention:blocker:07feb67b-25b6-587c-9f42-8b9b6a2013e8",
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
      "rank": 8
    }
  ],
  "receipts": []
}
"""#

    static let routedUnassigned = #"""
{
  "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
  "generatedAt": "2026-11-16T17:36:07.550Z",
  "totalCount": 0,
  "deskBadgeCount": 8,
  "viewCounts": {
    "mine": 8,
    "unassigned": 0,
    "company": 0,
    "archived": 0,
    "all": 8
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
  "items": []
}
"""#

    static let routedCompany = #"""
{
  "companyId": "eab54639-a87c-5ff6-9461-9f1fa55eff5e",
  "generatedAt": "2026-11-16T17:36:07.628Z",
  "totalCount": 0,
  "deskBadgeCount": 8,
  "viewCounts": {
    "mine": 8,
    "unassigned": 0,
    "company": 0,
    "archived": 0,
    "all": 8
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
  "items": []
}
"""#

    static let routedDirectory = #"""
{
  "users": [
    {
      "principalId": "routed-user-1",
      "status": "active",
      "membershipRole": "operator",
      "user": {
        "id": "routed-user-1",
        "email": "user@example.test",
        "name": "Sandbox Reviewer",
        "image": null
      }
    },
    {
      "principalId": "routed-user-2",
      "status": "active",
      "membershipRole": "owner",
      "user": {
        "id": "routed-user-2",
        "email": "user@example.test",
        "name": "Sandbox Board",
        "image": null
      }
    }
  ]
}
"""#

}
