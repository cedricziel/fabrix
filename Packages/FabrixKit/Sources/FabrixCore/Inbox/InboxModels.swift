import Foundation

public enum AttentionView: String, CaseIterable, Sendable, Codable { case mine, unassigned, company }
public struct AttentionSource: Hashable, Sendable, Codable { public var kind: String; public var id: String; public init(kind:String,id:String){self.kind=kind;self.id=id} }
public enum AttentionCardType: Hashable, Sendable, Codable, CaseIterable { case answerQuestions, makeChoice, reviewPlan, confirm, suggestedTasks, reviewDeliverable, reviewItems, boardApproval, joinRequest, toolAccess, connectService, reviewTask, failedRun, budgetStop, blockedTask, recovery, unknown(String)
 public var rawValue:String { switch self { case .answerQuestions:"answer_questions";case .makeChoice:"make_choice";case .reviewPlan:"review_plan";case .confirm:"confirm";case .suggestedTasks:"suggested_tasks";case .reviewDeliverable:"review_deliverable";case .reviewItems:"review_items";case .boardApproval:"board_approval";case .joinRequest:"join_request";case .toolAccess:"tool_access";case .connectService:"connect_service";case .reviewTask:"review_task";case .failedRun:"failed_run";case .budgetStop:"budget_stop";case .blockedTask:"blocked_task";case .recovery:"recovery";case .unknown(let x):x } }
 public init(rawValue:String){ self = ["answer_questions":.answerQuestions,"make_choice":.makeChoice,"review_plan":.reviewPlan,"confirm":.confirm,"suggested_tasks":.suggestedTasks,"review_deliverable":.reviewDeliverable,"review_items":.reviewItems,"board_approval":.boardApproval,"join_request":.joinRequest,"tool_access":.toolAccess,"connect_service":.connectService,"review_task":.reviewTask,"failed_run":.failedRun,"budget_stop":.budgetStop,"blocked_task":.blockedTask,"recovery":.recovery][rawValue] ?? .unknown(rawValue) }
 public static var allCases:[Self] { [.answerQuestions,.makeChoice,.reviewPlan,.confirm,.suggestedTasks,.reviewDeliverable,.reviewItems,.boardApproval,.joinRequest,.toolAccess,.connectService,.reviewTask,.failedRun,.budgetStop,.blockedTask,.recovery] }
 public init(from decoder:Decoder)throws{self.init(rawValue:try decoder.singleValueContainer().decode(String.self))}; public func encode(to encoder:Encoder)throws{var c=encoder.singleValueContainer();try c.encode(rawValue)}
}
public enum AttentionAnswer: Hashable, Sendable, Codable {
    case approval(sourceID: String)
    case confirmation
    case questions
    case verdicts
    case openInPaperclip

    public static func answerPerCardType(
        _ type: AttentionCardType,
        sourceID: String,
        isCheckboxConfirmation: Bool = false,
        isTextOnlyQuestion: Bool = false,
        isWorkflowRequest: Bool = false,
        hasUnknownSourceOrStatus: Bool = false
    ) -> Self {
        if isCheckboxConfirmation || isTextOnlyQuestion || isWorkflowRequest || hasUnknownSourceOrStatus {
            return .openInPaperclip
        }

        switch type {
        case .boardApproval:
            return .approval(sourceID: sourceID)
        case .confirm, .reviewPlan, .reviewDeliverable:
            return .confirmation
        case .answerQuestions:
            return .questions
        case .reviewItems:
            return .verdicts
        default:
            return .openInPaperclip
        }
    }
}

public struct AttentionTaskRef: Hashable, Sendable, Codable {
    public var id: String
    public var identifier: String?
    public var title: String?
    public var status: String?

    public init(id: String, identifier: String? = nil, title: String? = nil, status: String? = nil) {
        self.id = id
        self.identifier = identifier
        self.title = title
        self.status = status
    }
}

public struct AttentionAudience: Hashable, Sendable, Codable {
    public var kind: String
    public var userID: String?
    public var reason: String?
    public var transferredByUserID: String?

    public init(kind: String, userID: String? = nil, reason: String? = nil, transferredByUserID: String? = nil) {
        self.kind = kind
        self.userID = userID
        self.reason = reason
        self.transferredByUserID = transferredByUserID
    }
}
public struct AttentionItem: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var source: AttentionSource
    public var cardType: AttentionCardType
    public var answer: AttentionAnswer
    public var title: String
    public var summary: String?
    public var requester: RequesterRef?
    public var task: AttentionTaskRef?
    public var projectName: String?
    public var isCritical: Bool
    public var isProblem: Bool
    public var staleReason: String?
    public var createdAt: Date
    public var activityAt: Date
    public var webPath: String?
    public var audience: AttentionAudience?
    public var closeModes: [String]
    public var canClaim: Bool
    public var canTransfer: Bool
    public var fingerprint: String?
    public var obligationKey: String?
    public var obligationLeadID: String?
    public var evidence: [AttentionItem]

    public init(
        id: String, source: AttentionSource, cardType: AttentionCardType,
        answer: AttentionAnswer = .openInPaperclip, title: String,
        summary: String? = nil, requester: RequesterRef? = nil, task: AttentionTaskRef? = nil,
        projectName: String? = nil, isCritical: Bool = false, isProblem: Bool = false,
        staleReason: String? = nil, createdAt: Date, activityAt: Date,
        webPath: String? = nil, audience: AttentionAudience? = nil, closeModes: [String] = [],
        canClaim: Bool = false, canTransfer: Bool = false, fingerprint: String? = nil,
        obligationKey: String? = nil, obligationLeadID: String? = nil, evidence: [AttentionItem] = []
    ) {
        self.id = id; self.source = source; self.cardType = cardType; self.answer = answer
        self.title = title; self.summary = summary; self.requester = requester; self.task = task
        self.projectName = projectName; self.isCritical = isCritical; self.isProblem = isProblem
        self.staleReason = staleReason; self.createdAt = createdAt; self.activityAt = activityAt
        self.webPath = webPath; self.audience = audience; self.closeModes = closeModes
        self.canClaim = canClaim; self.canTransfer = canTransfer; self.fingerprint = fingerprint
        self.obligationKey = obligationKey; self.obligationLeadID = obligationLeadID; self.evidence = evidence
    }
}
public struct AttentionFeed: Hashable, Sendable, Codable {
    public var items: [AttentionItem]
    public var deskBadgeCount: Int
    public var viewCounts: [AttentionView: Int]?
    public var nextCursor: String?
    public var receipts: [AttentionReceipt]
    public var supportsRouting: Bool { viewCounts != nil }

    public init(items: [AttentionItem], deskBadgeCount: Int, viewCounts: [AttentionView: Int]? = nil, nextCursor: String? = nil, receipts: [AttentionReceipt] = []) {
        self.items = items
        self.deskBadgeCount = deskBadgeCount
        self.viewCounts = viewCounts
        self.nextCursor = nextCursor
        self.receipts = receipts
    }
}
public struct AttentionReceipt: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var title: String
    public var dismissalKey: String
    public var source: AttentionSource
    public var outcome: String
    public var actorUserID: String
    public var transferredToUserID: String?
    public var reason: String?
    public var task: AttentionTaskRef?
    public var webPath: String?
    public var createdAt: Date
    public var expiresAt: Date

    public init(
        id: String, title: String, dismissalKey: String, source: AttentionSource,
        outcome: String, actorUserID: String, transferredToUserID: String? = nil,
        reason: String? = nil, task: AttentionTaskRef? = nil, webPath: String? = nil,
        createdAt: Date, expiresAt: Date
    ) {
        self.id = id; self.title = title; self.dismissalKey = dismissalKey; self.source = source
        self.outcome = outcome; self.actorUserID = actorUserID; self.transferredToUserID = transferredToUserID
        self.reason = reason; self.task = task; self.webPath = webPath
        self.createdAt = createdAt; self.expiresAt = expiresAt
    }
}
public struct Person: Identifiable, Hashable, Sendable, Codable {
    public var id: String
    public var name: String?
    public var email: String?

    public init(id: String, name: String? = nil, email: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
    }
}
public struct RequesterRef: Hashable, Sendable, Codable {
    public var id: String
    public var name: String?
    public var kind: String

    public init(id: String, name: String? = nil, kind: String = "user") {
        self.id = id
        self.name = name
        self.kind = kind
    }
}
