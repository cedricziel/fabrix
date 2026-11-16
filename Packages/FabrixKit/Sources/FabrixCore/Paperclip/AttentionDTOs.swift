import Foundation

struct AttentionFeedDTO: Decodable {
    private enum CodingKeys: String, CodingKey { case items, deskBadgeCount, viewCounts, nextCursor, receipts }

    var items: [Lenient<AttentionItemDTO>]
    var deskBadgeCount: Int
    var viewCounts: [String: Int]?
    var nextCursor: String?
    var receipts: [Lenient<AttentionReceiptDTO>]?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([Lenient<AttentionItemDTO>].self, forKey: .items)
        deskBadgeCount = try container.decode(Int.self, forKey: .deskBadgeCount)
        viewCounts = try? container.decodeIfPresent([String: Int].self, forKey: .viewCounts)
        nextCursor = try? container.decodeIfPresent(String.self, forKey: .nextCursor)
        receipts = try? container.decodeIfPresent([Lenient<AttentionReceiptDTO>].self, forKey: .receipts)
    }
}

struct AttentionReceiptDTO: Decodable {
    private enum CodingKeys: String, CodingKey { case id, dismissalKey, outcome, sourceKind, sourceId, title, actorUserId, createdAt, expiresAt, reason, transferredToUserId, href, issue }

    var id: String
    var dismissalKey: String
    var outcome: String
    var sourceKind: String
    var sourceId: String
    var title: String
    var actorUserId: String
    var createdAt: Date
    var expiresAt: Date
    var reason: String?
    var transferredToUserId: String?
    var href: String?
    var issue: AttentionReceiptIssueDTO?

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id); dismissalKey = try c.decode(String.self, forKey: .dismissalKey)
        outcome = try c.decode(String.self, forKey: .outcome); sourceKind = try c.decode(String.self, forKey: .sourceKind)
        sourceId = try c.decode(String.self, forKey: .sourceId); title = try c.decode(String.self, forKey: .title)
        actorUserId = try c.decode(String.self, forKey: .actorUserId); createdAt = try c.decode(Date.self, forKey: .createdAt)
        expiresAt = try c.decode(Date.self, forKey: .expiresAt)
        reason = try? c.decodeIfPresent(String.self, forKey: .reason)
        transferredToUserId = try? c.decodeIfPresent(String.self, forKey: .transferredToUserId)
        href = try? c.decodeIfPresent(String.self, forKey: .href)
        issue = try? c.decodeIfPresent(AttentionReceiptIssueDTO.self, forKey: .issue)
    }
}

struct AttentionReceiptIssueDTO: Decodable {
    private enum CodingKeys: String, CodingKey { case id, title, identifier, href }
    var id: String
    var title: String
    var identifier: String?
    var href: String?
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id); title = try c.decode(String.self, forKey: .title)
        identifier = try? c.decodeIfPresent(String.self, forKey: .identifier)
        href = try? c.decodeIfPresent(String.self, forKey: .href)
    }
}

struct AttentionItemDTO: Decodable {
    private enum CodingKeys: String, CodingKey { case id, sourceKind, subject, createdAt, activityAt, whyNow, severity, detail, relatedIssue, requester, audience, stale, project, closeModes, changeFingerprint, obligationKey, obligationLeadId }

    var id: String
    var sourceKind: String
    var subject: AttentionSubjectDTO
    var createdAt: Date
    var activityAt: Date
    var whyNow: String?
    var severity: String?
    var detail: [String: JSONValue]?
    var relatedIssue: AttentionSubjectDTO?
    var requester: [String: JSONValue]?
    var audience: [String: JSONValue]?
    var stale: [String: JSONValue]?
    var project: [String: JSONValue]?
    var closeModes: [String]?
    var changeFingerprint: String?
    var obligationKey: String?
    var obligationLeadId: String?

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        sourceKind = try c.decode(String.self, forKey: .sourceKind)
        subject = try c.decode(AttentionSubjectDTO.self, forKey: .subject)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        activityAt = try c.decode(Date.self, forKey: .activityAt)
        whyNow = try? c.decodeIfPresent(String.self, forKey: .whyNow)
        severity = try? c.decodeIfPresent(String.self, forKey: .severity)
        detail = try? c.decodeIfPresent([String: JSONValue].self, forKey: .detail)
        relatedIssue = try? c.decodeIfPresent(AttentionSubjectDTO.self, forKey: .relatedIssue)
        requester = try? c.decodeIfPresent([String: JSONValue].self, forKey: .requester)
        audience = try? c.decodeIfPresent([String: JSONValue].self, forKey: .audience)
        stale = try? c.decodeIfPresent([String: JSONValue].self, forKey: .stale)
        project = try? c.decodeIfPresent([String: JSONValue].self, forKey: .project)
        closeModes = try? c.decodeIfPresent([String].self, forKey: .closeModes)
        changeFingerprint = try? c.decodeIfPresent(String.self, forKey: .changeFingerprint)
        obligationKey = try? c.decodeIfPresent(String.self, forKey: .obligationKey)
        obligationLeadId = try? c.decodeIfPresent(String.self, forKey: .obligationLeadId)
    }
}

struct AttentionSubjectDTO: Decodable {
    private enum CodingKeys: String, CodingKey { case kind, id, title, status, identifier, href, metadata }

    var kind: String
    var id: String
    var title: String
    var status: String?
    var identifier: String?
    var href: String?
    var metadata: [String: JSONValue]?

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(String.self, forKey: .kind)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        status = try? c.decodeIfPresent(String.self, forKey: .status)
        identifier = try? c.decodeIfPresent(String.self, forKey: .identifier)
        href = try? c.decodeIfPresent(String.self, forKey: .href)
        metadata = try? c.decodeIfPresent([String: JSONValue].self, forKey: .metadata)
    }
}

struct UserDirectoryDTO: Decodable {
    var users: [Lenient<DirectoryMemberDTO>]

    func people() -> [Person] {
        users.compactMap { row in
            guard let member = row.value, member.status == "active" else { return nil }
            return Person(id: member.principalId, name: member.user?.name, email: member.user?.email)
        }
    }
}

struct DirectoryMemberDTO: Decodable {
    private enum CodingKeys: String, CodingKey { case principalId, status, user }
    var principalId: String
    var status: String
    var user: DirectoryUserDTO?

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        principalId = try c.decode(String.self, forKey: .principalId)
        status = try c.decode(String.self, forKey: .status)
        user = try? c.decodeIfPresent(DirectoryUserDTO.self, forKey: .user)
    }
}

struct DirectoryUserDTO: Decodable {
    private enum CodingKeys: String, CodingKey { case id, name, email }
    var id: String
    var name: String?
    var email: String?

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try? c.decodeIfPresent(String.self, forKey: .name)
        email = try? c.decodeIfPresent(String.self, forKey: .email)
    }
}
