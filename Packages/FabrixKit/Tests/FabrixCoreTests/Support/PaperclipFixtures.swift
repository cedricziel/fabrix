@testable import FabrixCore
/// Response bodies shaped after Paperclip's shared types
/// (packages/shared/src/types/{company,agent,issue,approval,heartbeat,activity}.ts).
enum PaperclipFixtures {
    static let proxyHeader = [CustomHeader(name: "X-Proxy-Token", value: "proxy-secret")]

    static let companyID = "5f1c3c52-8d7b-4b8e-9a51-0b8f0f6f1a01"

    static let company = """
    {
      "id": "\(companyID)",
      "name": "Atlas",
      "description": "Ship the calmest task app on the App Store",
      "status": "active",
      "pauseReason": null,
      "pausedAt": null,
      "issuePrefix": "ATL",
      "issueCounter": 160,
      "budgetMonthlyCents": 100000,
      "spentMonthlyCents": 40200,
      "requireBoardApprovalForNewAgents": true,
      "feedbackDataSharingEnabled": false,
      "logoAssetId": null,
      "logoUrl": null,
      "createdAt": "2026-10-01T08:00:00.000Z",
      "updatedAt": "2026-11-06T17:12:44.512Z"
    }
    """

    static let companies = "[\(company), \(pausedCompany)]"

    static let pausedCompany = """
    {
      "id": "c2", "name": "Beacon", "description": null, "status": "paused",
      "pauseReason": "manual", "pausedAt": "2026-11-01T10:00:00Z", "issuePrefix": "BEA",
      "issueCounter": 3, "budgetMonthlyCents": 0, "spentMonthlyCents": 0,
      "createdAt": "2026-10-20T08:00:00Z", "updatedAt": "2026-11-01T10:00:00Z"
    }
    """

    static let agents = """
    [
      {
        "id": "a-ceo", "companyId": "\(companyID)", "name": "CEO", "urlKey": "ceo", "role": "ceo",
        "title": "Chief Executive", "icon": null, "status": "pending_approval", "reportsTo": null,
        "capabilities": null, "adapterType": "claude_local", "adapterConfig": {}, "runtimeConfig": {},
        "budgetMonthlyCents": 15000, "spentMonthlyCents": 6210, "pauseReason": null, "pausedAt": null,
        "permissions": { "canCreateAgents": true }, "lastHeartbeatAt": "2026-11-07T09:58:00.000Z",
        "metadata": null, "createdAt": "2026-10-01T08:00:00.000Z", "updatedAt": "2026-11-07T09:58:00.000Z"
      },
      {
        "id": "a-cto", "companyId": "\(companyID)", "name": "CTO", "urlKey": "cto", "role": "cto",
        "title": null, "status": "running", "reportsTo": "a-ceo", "adapterType": "codex_local",
        "adapterConfig": {}, "runtimeConfig": {}, "budgetMonthlyCents": 0, "spentMonthlyCents": 9840,
        "pauseReason": null, "pausedAt": null, "permissions": {}, "lastHeartbeatAt": null, "metadata": null,
        "createdAt": "2026-10-01T08:00:00Z", "updatedAt": "2026-11-07T09:58:00Z"
      },
      {
        "id": "a-ops", "companyId": "\(companyID)", "name": "DevOps", "urlKey": "devops", "role": "engineer",
        "title": "Infrastructure", "status": "paused", "reportsTo": "a-cto", "adapterType": "claude_local",
        "adapterConfig": {}, "runtimeConfig": {}, "budgetMonthlyCents": 6000, "spentMonthlyCents": 1230,
        "pauseReason": "manual", "pausedAt": "2026-11-05T12:00:00Z", "permissions": {}, "lastHeartbeatAt": null,
        "metadata": null, "createdAt": "2026-10-01T08:00:00Z", "updatedAt": "2026-11-05T12:00:00Z"
      },
      {
        "id": "a-old", "companyId": "\(companyID)", "name": "Retired", "urlKey": "retired", "role": "general",
        "title": null, "status": "terminated", "reportsTo": null, "adapterType": "process",
        "adapterConfig": {}, "runtimeConfig": {}, "budgetMonthlyCents": 0, "spentMonthlyCents": 0,
        "pauseReason": null, "pausedAt": null, "permissions": {}, "lastHeartbeatAt": null, "metadata": null,
        "createdAt": "2026-10-01T08:00:00Z", "updatedAt": "2026-10-02T08:00:00Z"
      }
    ]
    """

    static let issues = """
    [
      {
        "id": "i-142", "companyId": "\(companyID)", "projectId": null, "goalId": null, "parentId": null,
        "title": "Split sync worker into queue consumers", "description": null, "status": "in_progress",
        "workMode": "standard", "priority": "high", "assigneeAgentId": "a-cto", "assigneeUserId": null,
        "checkoutRunId": "r-1", "executionRunId": "r-1", "issueNumber": 142, "identifier": "ATL-142",
        "createdAt": "2026-11-06T08:00:00.000Z", "updatedAt": "2026-11-07T09:50:00.000Z"
      },
      {
        "id": "i-160", "companyId": "\(companyID)", "projectId": "p-mobile", "projectWorkspaceId": null,
        "title": "Evaluate push provider", "status": "backlog",
        "workMode": "standard", "priority": "low", "assigneeAgentId": null, "issueNumber": 160,
        "identifier": "ATL-160", "createdAt": "2026-11-06T08:00:00Z", "updatedAt": "2026-11-06T08:00:00Z"
      }
    ]
    """

    static let approvals = """
    [
      {
        "id": "ap-hire", "companyId": "\(companyID)", "type": "hire_agent", "requestedByAgentId": "a-ceo",
        "requestedByUserId": null, "status": "pending",
        "payload": { "name": "Designer", "role": "designer", "title": "Product Designer", "adapterType": "claude_local", "capabilities": "UI and brand", "desiredSkills": ["figma"] },
        "decisionNote": null, "decidedByUserId": null, "decidedAt": null,
        "createdAt": "2026-11-07T09:48:00.000Z", "updatedAt": "2026-11-07T09:48:00.000Z"
      },
      {
        "id": "ap-plan", "companyId": "\(companyID)", "type": "approve_ceo_strategy", "requestedByAgentId": "a-ceo",
        "status": "revision_requested", "payload": { "title": "Q4 plan", "plan": "Retention over new features." },
        "createdAt": "2026-11-07T09:00:00Z", "updatedAt": "2026-11-07T09:00:00Z"
      },
      {
        "id": "ap-budget", "companyId": "\(companyID)", "type": "budget_override_required", "requestedByAgentId": null,
        "requestedByUserId": "u-1", "status": "pending",
        "payload": { "scopeType": "agent", "scopeName": "CTO", "budgetAmount": 25000, "observedAmount": 24100, "guidance": "Raise the cap or pause the agent." },
        "createdAt": "2026-11-07T08:00:00Z", "updatedAt": "2026-11-07T08:00:00Z"
      },
      {
        "id": "ap-other", "companyId": "\(companyID)", "type": "something_new", "status": "cancelled",
        "payload": {}, "createdAt": "2026-11-07T07:00:00Z", "updatedAt": "2026-11-07T07:00:00Z"
      }
    ]
    """

    static let heartbeatRuns = """
    [
      {
        "id": "r-1", "companyId": "\(companyID)", "agentId": "a-cto", "scopeKind": "issue", "issueId": "i-142",
        "invocationSource": "assignment", "triggerDetail": "system", "status": "running",
        "startedAt": "2026-11-07T09:48:00.000Z", "finishedAt": null, "error": null, "exitCode": null,
        "usageJson": null, "resultJson": null, "createdAt": "2026-11-07T09:47:58.000Z", "updatedAt": "2026-11-07T09:48:00.000Z"
      },
      {
        "id": "r-0", "companyId": "\(companyID)", "agentId": "a-cto", "scopeKind": "company", "issueId": null,
        "invocationSource": "timer", "triggerDetail": "system", "status": "succeeded",
        "startedAt": "2026-11-07T09:00:00Z", "finishedAt": "2026-11-07T09:04:00Z", "error": null, "exitCode": 0,
        "costUsd": "1.92", "inputTokens": "1200", "outputTokens": "300",
        "usageJson": { "inputTokens": 1200, "outputTokens": 300 },
        "resultJson": { "summary": "opened PR #84" },
        "createdAt": "2026-11-07T09:00:00Z", "updatedAt": "2026-11-07T09:04:00Z"
      },
      {
        "id": "r-q", "companyId": "\(companyID)", "agentId": "a-ceo", "scopeKind": "company", "issueId": null,
        "invocationSource": "on_demand", "status": "queued", "startedAt": null, "finishedAt": null,
        "createdAt": "2026-11-07T09:59:00Z", "updatedAt": "2026-11-07T09:59:00Z"
      }
    ]
    """

    static let activity = """
    [
      {
        "id": "e-1", "companyId": "\(companyID)", "actorType": "agent", "actorId": "a-cto", "action": "issue.updated",
        "entityType": "issue", "entityId": "i-142", "agentId": "a-cto", "runId": "r-1",
        "details": { "identifier": "ATL-142", "status": "in_progress" }, "createdAt": "2026-11-07T09:50:00.000Z"
      },
      {
        "id": "e-2", "companyId": "\(companyID)", "actorType": "user", "actorId": "u-1", "action": "agent.paused",
        "entityType": "agent", "entityId": "a-ops", "agentId": null, "runId": null, "details": null,
        "createdAt": "2026-11-05T12:00:00Z"
      },
      {
        "id": "e-3", "companyId": "\(companyID)", "actorType": "user", "actorId": "u-1", "action": "project.created",
        "entityType": "project", "entityId": "p-mobile", "agentId": null, "runId": null,
        "details": { "name": "Mobile app", "repositories": [] }, "createdAt": "2026-11-04T12:00:00Z"
      }
    ]
    """

    /// Recorded from a Paperclip sandbox (`GET /api/companies/{id}/projects`), trimmed to the fields Fabrix reads
    /// plus a few it ignores. Platform's status is made up to stand for a value from a newer server.
    static let projects = """
    [
      {
        "id": "p-mobile", "companyId": "\(companyID)", "urlKey": "mobile-app", "goalId": "g-1",
        "goalIds": ["g-1"], "goals": [{ "id": "g-1", "title": "Ship v1 of the Atlas mobile app" }],
        "name": "Mobile app", "description": "iOS and Android client", "visibility": "open",
        "status": "in_progress", "leadAgentId": "a-cto", "targetDate": "2026-12-15", "color": "#0F766E",
        "icon": null, "env": null, "pauseReason": null, "pausedAt": null, "executionWorkspacePolicy": null,
        "archivedAt": null, "createdAt": "2026-11-07T13:26:52.387Z", "updatedAt": "2026-11-07T13:26:52.387Z",
        "codebase": { "workspaceId": "w-1", "repoUrl": "https://github.com/atlas/mobile", "repoName": "mobile", "origin": "managed_checkout" },
        "workspaces": [
          {
            "id": "w-1", "projectId": "p-mobile", "name": "atlas/mobile", "sourceType": "git_repo", "cwd": null,
            "repoUrl": "https://github.com/atlas/mobile", "repoRef": null, "defaultRef": "main", "visibility": "default",
            "isPrimary": true, "runtimeServices": [], "createdAt": "2026-11-07T13:26:52.387Z"
          },
          {
            "id": "w-2", "projectId": "p-mobile", "name": "ops scripts", "sourceType": "local_path", "cwd": "/srv/atlas/ops",
            "repoUrl": null, "repoRef": null, "defaultRef": null, "visibility": "advanced", "isPrimary": false
          }
        ],
        "taskCount": 4, "budget": null
      },
      {
        "id": "p-platform", "companyId": "\(companyID)", "urlKey": "platform", "goalId": null, "goalIds": [], "goals": [],
        "name": "Platform", "description": null, "status": "on_hold", "leadAgentId": null, "targetDate": null,
        "color": null, "archivedAt": null, "workspaces": [], "taskCount": 1, "budget": null
      }
    ]
    """

    static let me = """
    {
      "user": { "id": "u-1", "name": "Ada Board", "email": "ada@example.com" },
      "userId": "u-1", "isInstanceAdmin": false, "companyIds": ["\(companyID)"],
      "memberships": [], "source": "board_key", "keyId": "k-1"
    }
    """

    static let agentPaused = """
    { "id": "a-ops", "companyId": "\(companyID)", "name": "DevOps", "status": "paused", "adapterType": "claude_local", "budgetMonthlyCents": 6000, "spentMonthlyCents": 1230 }
    """

    static let agentIdle = """
    { "id": "a-cto", "companyId": "\(companyID)", "name": "CTO", "status": "idle", "adapterType": "codex_local", "budgetMonthlyCents": 0, "spentMonthlyCents": 0 }
    """
}
