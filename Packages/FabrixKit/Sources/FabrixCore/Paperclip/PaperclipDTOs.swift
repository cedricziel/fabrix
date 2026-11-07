import Foundation

// Wire shapes from Paperclip's packages/shared/src/types. Only the fields Fabrix
// reads are declared; statuses stay raw strings so unknown values never fail decoding.

struct CompanyDTO: Decodable {
    var id: String
    var name: String
    var description: String?
    var status: String
    var budgetMonthlyCents: Int?
    var spentMonthlyCents: Int?
}

struct AgentDTO: Decodable {
    var id: String
    var name: String
    var role: String?
    var title: String?
    var status: String
    var reportsTo: String?
    var adapterType: String?
    var budgetMonthlyCents: Int?
    var spentMonthlyCents: Int?
}

struct IssueDTO: Decodable {
    var id: String
    var identifier: String?
    var title: String
    var status: String
    var assigneeAgentId: String?
    var updatedAt: Date?
    var projectId: String?
}

struct ProjectDTO: Decodable {
    struct Goal: Decodable {
        var title: String
    }

    var id: String
    var name: String
    var description: String?
    var status: String
    var leadAgentId: String?
    /// `YYYY-MM-DD`, a calendar date.
    var targetDate: String?
    var color: String?
    var goals: [Goal]?
    /// Kept as text: only its presence matters.
    var archivedAt: String?
    var workspaces: [Lenient<ProjectWorkspaceDTO>]?
    var taskCount: Int?
}

/// Decodes to nil instead of failing, so one malformed row doesn't fail a whole list.
struct Lenient<Value: Decodable>: Decodable {
    var value: Value?

    init(from decoder: any Decoder) throws {
        value = try? Value(from: decoder)
    }
}

struct ProjectWorkspaceDTO: Decodable {
    var id: String
    var name: String
    var sourceType: String
    var cwd: String?
    var repoUrl: String?
    var repoRef: String?
    var defaultRef: String?
    var isPrimary: Bool?
}

struct ApprovalDTO: Decodable {
    var id: String
    var type: String
    var status: String
    var requestedByAgentId: String?
    var payload: [String: JSONValue]?
    var createdAt: Date
    var updatedAt: Date?
}

struct HeartbeatRunDTO: Decodable {
    var id: String
    var agentId: String
    var issueId: String?
    var invocationSource: String?
    var status: String
    var startedAt: Date?
    var finishedAt: Date?
    var createdAt: Date
    var updatedAt: Date?
    var error: String?
    /// Run-list rows carry cost at the top level; Postgres numerics may arrive as strings.
    var costUsd: JSONValue?
    var usageJson: [String: JSONValue]?
    var resultJson: [String: JSONValue]?
}

struct ActivityDTO: Decodable {
    var id: String
    var actorType: String
    var actorId: String
    var action: String
    var entityType: String
    var entityId: String
    var details: [String: JSONValue]?
    var createdAt: Date
}

struct BoardMeDTO: Decodable {
    struct User: Decodable {
        var name: String?
    }

    var user: User?
    var userId: String
    var isInstanceAdmin: Bool?
    var companyIds: [String]?
    /// The board key the request used; nil for session and local-trusted access.
    var keyId: String?
}

struct SignInChallengeCreatedDTO: Decodable {
    var id: String
    var token: String
    var boardApiToken: String
    var approvalPath: String
    var approvalUrl: String?
    var expiresAt: Date?
    var suggestedPollIntervalMs: Int?
}

struct BoardAPIKeyDTO: Decodable {
    var id: String
    var expiresAt: Date?
}

struct SignInChallengeStatusDTO: Decodable {
    var status: String
}

struct ErrorBodyDTO: Decodable {
    var error: String
}

/// Free-form JSON, for Paperclip's `payload`, `details`, `usageJson` and `resultJson` objects.
enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = try .object(container.decode([String: JSONValue].self))
        }
    }

    /// Non-empty text, with numbers rendered without a trailing ".0".
    var text: String? {
        switch self {
        case let .string(value): value.isEmpty ? nil : value
        case let .number(value): Int(exactly: value).map(String.init) ?? String(value)
        default: nil
        }
    }

    /// A number, or a string holding one.
    var number: Double? {
        switch self {
        case let .number(value): value
        case let .string(value): Double(value)
        default: nil
        }
    }
}
