import Foundation

/// The seam between UI and a Paperclip server. Features depend only on this.
public protocol FactoryService: Sendable {
    func companies() async throws -> [Company]
    func snapshot(companyID: Company.ID) async throws -> CompanySnapshot
    func decide(approvalID: Approval.ID, approve: Bool) async throws
    func wake(agentID: Agent.ID) async throws
    func pause(agentID: Agent.ID) async throws
    func setCompanyPaused(_ paused: Bool, companyID: Company.ID) async throws
    /// When the credential this service uses stops working, if the server says.
    func credentialExpiry() async throws -> Date?
}

public extension FactoryService {
    func credentialExpiry() async throws -> Date? {
        nil
    }
}
