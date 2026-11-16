import Foundation

extension AttentionFeedDTO {
    func domainFeed() -> AttentionFeed {
        let counts = viewCounts.map { values in
            Dictionary(uniqueKeysWithValues: values.compactMap { key, value in
                AttentionView(rawValue: key).map { ($0, value) }
            })
        }
        return AttentionFeed(
            items: foldAttentionEvidence(items.compactMap(\.value).map { $0.domainItem(supportsRouting: viewCounts != nil) }),
            deskBadgeCount: deskBadgeCount,
            viewCounts: counts,
            nextCursor: nextCursor,
            receipts: receipts?.compactMap(\.value).map { $0.domainReceipt() } ?? []
        )
    }
}

extension AttentionReceiptDTO {
    func domainReceipt() -> AttentionReceipt {
        AttentionReceipt(
            id: id,
            title: title,
            dismissalKey: dismissalKey,
            source: AttentionSource(kind: sourceKind, id: sourceId),
            outcome: outcome,
            actorUserID: actorUserId,
            transferredToUserID: transferredToUserId,
            reason: reason,
            task: issue.map { AttentionTaskRef(id: $0.id, identifier: $0.identifier, title: $0.title) },
            webPath: href ?? issue?.href,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
    }
}

func foldAttentionEvidence(_ items: [AttentionItem]) -> [AttentionItem] {
    var counts: [String: Int] = [:]
    for item in items { counts[item.id, default: 0] += 1 }
    let indexed = Dictionary(items.enumerated().map { ($0.element.id, $0.offset) }, uniquingKeysWith: { first, _ in first })
    let hasChildren = Set<String>(items.compactMap { item in
        guard let leadID = item.obligationLeadID, leadID != item.id else { return nil }
        return leadID
    })
    var folded = Set<Int>()
    var result = items
    for (index, item) in items.enumerated() {
        guard let leadID = item.obligationLeadID, leadID != item.id,
              counts[item.id] == 1, counts[leadID] == 1,
              let leadIndex = indexed[leadID], leadIndex != index,
              !hasChildren.contains(item.id),
              items[leadIndex].obligationLeadID == nil || items[leadIndex].obligationLeadID == leadID else { continue }
        result[leadIndex].evidence.append(item)
        folded.insert(index)
    }
    return result.enumerated().compactMap { folded.contains($0.offset) ? nil : $0.element }
}

extension AttentionItemDTO {
    func domainItem(supportsRouting: Bool) -> AttentionItem {
        let type = cardType
        let requesterRef: RequesterRef? = {
            guard let requester,
                  let id = requester["id"]?.text,
                  let kind = requester["kind"]?.text else { return nil }
            return RequesterRef(id: id, name: requester["name"]?.text, kind: kind)
        }()
        let taskDTO = relatedIssue ?? (subject.kind == "issue" ? subject : nil)
        let task = taskDTO.map {
            AttentionTaskRef(id: $0.id, identifier: $0.identifier, title: $0.title, status: $0.status)
        }
        let audienceValue: AttentionAudience? = {
            guard let audience, let kind = audience["kind"]?.text else { return nil }
            return AttentionAudience(
                kind: kind,
                userID: audience["userId"]?.text,
                reason: audience["reason"]?.text,
                transferredByUserID: audience["transferredByUserId"]?.text
            )
        }()
        let problem: Bool
        switch type {
        case .failedRun, .budgetStop, .blockedTask, .recovery: problem = true
        default: problem = false
        }
        return AttentionItem(
            id: id,
            source: AttentionSource(kind: sourceKind, id: subject.id),
            cardType: type,
            answer: answer,
            title: subject.title,
            summary: whyNow,
            requester: requesterRef,
            task: task,
            projectName: project?["name"]?.text,
            isCritical: severity == "critical",
            isProblem: problem,
            staleReason: stale?["reason"]?.text,
            createdAt: createdAt,
            activityAt: activityAt,
            webPath: subject.href ?? relatedIssue?.href,
            audience: audienceValue,
            closeModes: supportsRouting ? (closeModes ?? []) : [],
            canClaim: canClaim(supportsRouting: supportsRouting),
            canTransfer: canTransfer(supportsRouting: supportsRouting),
            fingerprint: changeFingerprint,
            obligationKey: obligationKey,
            obligationLeadID: obligationLeadId
        )
    }

    var isRecognizedPendingThread: Bool {
        guard sourceKind == "issue_thread_interaction",
              subject.kind == "interaction",
              subject.status == "pending" else { return false }
        if case .unknown = cardType { return false }
        let kind = subject.metadata?["kind"]?.text
        return ["request_confirmation", "request_checkbox_confirmation", "ask_user_questions", "suggest_tasks", "request_item_verdicts", "connection_intent"].contains(kind ?? "")
    }

    var answer: AttentionAnswer {
        if sourceKind == "approval", subject.kind == "approval", subject.status == "pending" {
            return .approval(sourceID: subject.id)
        }
        guard isRecognizedPendingThread else { return .openInPaperclip }
        let metadata = subject.metadata ?? [:]
        let kind = metadata["kind"]?.text
        let detailKind = detail?["kind"]?.text
        guard kind != "request_checkbox_confirmation", detailKind != "checkbox_confirmation" else { return .openInPaperclip }
        func isAbsent(_ key: String) -> Bool {
            guard let value = metadata[key] else { return true }
            if case .null = value { return true }
            return false
        }
        let requestKind = metadata["requestKind"]?.text
        guard !["tool_action", "secret", "access", "connection"].contains(requestKind ?? ""),
              isAbsent("toolAction"),
              isAbsent("secretProposal"),
              isAbsent("connectionAuthorization") else { return .openInPaperclip }
        switch cardType {
        case .confirm, .reviewPlan, .reviewDeliverable: return .confirmation
        case .reviewItems: return .verdicts
        default: return .openInPaperclip
        }
        // Question feeds omit answerMode/full questionSet; validate the full payload later.
    }

    func canClaim(supportsRouting: Bool) -> Bool {
        supportsRouting && isRecognizedPendingThread && audience?["kind"]?.text == "pool"
    }

    func canTransfer(supportsRouting: Bool) -> Bool {
        supportsRouting && isRecognizedPendingThread
    }

    var cardType: AttentionCardType {
        let metadata = subject.metadata ?? [:]
        func text(_ key: String) -> String? { metadata[key]?.text }
        func truthy(_ key: String) -> Bool {
            switch metadata[key] {
            case .bool(true): true
            default: false
            }
        }

        switch sourceKind {
        case "issue_thread_interaction":
            if let raw = metadata["requestKind"] {
                switch raw {
                case .null: break
                case .string(let value) where !value.isEmpty: break
                default: return .unknown("invalid_request_kind")
                }
            }
            let requestKind = text("requestKind")
            if let requestKind {
                switch requestKind {
                case "tool_action", "secret", "access": return .toolAccess
                case "connection": return .connectService
                case "deliverable": break
                default: return .unknown(requestKind)
                }
            }
            switch text("kind") {
            case "connection_intent": return .connectService
            case "ask_user_questions": return .answerQuestions
            case "suggest_tasks": return .suggestedTasks
            case "request_item_verdicts": return .reviewItems
            default: break
            }
            if truthy("isPlanTarget") { return .reviewPlan }
            if requestKind == "deliverable" { return .reviewDeliverable }
            if ["request_confirmation", "request_checkbox_confirmation"].contains(text("kind") ?? "") { return .confirm }
            return .unknown(text("kind") ?? sourceKind)
        case "decision": return .makeChoice
        case "approval": return .boardApproval
        case "join_request": return .joinRequest
        case "review":
            return text("reviewAttentionState") == "stalled" ? .blockedTask : .reviewTask
        case "blocker_attention": return .blockedTask
        case "failed_run", "agent_error_alert": return .failedRun
        case "budget_alert": return .budgetStop
        case "recovery_action": return .recovery
        default: return .unknown(sourceKind)
        }
    }
}
