/// Fabrix's own span and log attributes. Everything the OpenTelemetry semantic conventions
/// cover uses their names instead; Paperclip-specific data lives under `paperclip.*`.
public enum PaperclipAttribute: String, CaseIterable, Sendable {
    /// Set it to the factory's host; the exporter replaces it with the per-install hash.
    case factoryID = "paperclip.factory.id"
    case authMethod = "paperclip.auth.method"
    case approvalKind = "paperclip.approval.kind"
    case agentStatus = "paperclip.agent.status"
    case runAdapter = "paperclip.run.adapter"
    /// Filled in on export from `url.path`, with identifiers replaced by `{id}`.
    case apiRoute = "paperclip.api.route"

    public var summary: String {
        switch self {
        case .factoryID: "Salted per-install SHA-256 of the Paperclip factory's host, never the raw host or name."
        case .authMethod: "How the app authenticates to the factory: board_key, oidc or oidc+board_key."
        case .approvalKind: "Kind of approval acted on: hire, strategy, budget or other."
        case .agentStatus: "Agent status shown or changed: running, idle, paused, needsYou, blocked or error."
        case .runAdapter: "Adapter that executed an agent run, as reported by Paperclip."
        case .apiRoute: "Paperclip API route template such as /api/companies/{id}/agents, never concrete IDs."
        }
    }
}
