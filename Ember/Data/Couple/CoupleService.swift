import Foundation

// MARK: - CoupleService protocol
//
// The production boundary for real two-device couple mode. EMBER ships with
// a local same-device DEMO implementation only; this protocol defines what a
// real backend (e.g. Supabase with Row-Level Security) must implement, so
// that adding one is a matter of conforming — not redesigning.
//
// ─── PRIVACY INVARIANT (architectural, not behavioral) ─────────────────────
//
//   Private reflections live ONLY on their author's device and are NEVER
//   transmitted. The protocol has no method through which a partner could
//   request another partner's private content — not because it is forbidden
//   in documentation, but because IT DOES NOT EXIST in the interface.
//
// What crosses the wire in production:
//   * pairing invitations + membership records
//   * shared journey state (day completion markers)
//   * explicitly authored hand-off notes
//   * asymmetric step ASSIGNMENTS (which pool index each device draws from),
//     never their contents — content is authored in both apps identically
//
// What NEVER crosses the wire:
//   * private reflections, drafts, journal entries
//   * profile readings, check-ins, onboarding answers

nonisolated protocol CoupleService: Sendable {

    /// Creates a pairing invitation. Returns an opaque invite code the other
    /// adult enters on their own device.
    func createPairingInvitation(from role: CoupleMembership.Role) async throws -> PairingInvite

    /// Accepts an invite code; both devices become members of one pair.
    /// Returns THIS device's own membership (userID, role, pairID) — exactly
    /// what the client stores locally.
    @discardableResult
    func acceptPairing(code: String, as role: CoupleMembership.Role) async throws -> CoupleMembership

    /// Shared progress marker for a completed day. Both partners may write
    /// their own completions; neither can see private reflections.
    func shareDayCompletion(_ dayNumber: Int, by member: CoupleMembership) async throws

    /// Explicit hand-off: the author composes a note destined for the other
    /// partner. The only channel between partners besides shared progress.
    func sendHandOff(_ note: HandOffNote, from member: CoupleMembership) async throws

    /// Fetches hand-offs addressed TO the given member.
    func fetchHandOffs(for member: CoupleMembership) async throws -> [HandOffNote]

    /// Unpairing: revokes all future shared access in BOTH directions.
    /// Membership records are tombstoned; tokens stop resolving.
    func unpair(_ pairID: String, requestedBy: CoupleMembership) async throws
}

// MARK: - Models

nonisolated struct PairingInvite: Equatable, Sendable, Codable {
    /// Opaque, single-use, time-limited code shown/typed by the partners.
    let code: String
    let role: CoupleMembership.Role
    /// Seconds until the invite expires.
    let expiresIn: Int
}

nonisolated struct CoupleMembership: Equatable, Sendable, Codable {
    nonisolated enum Role: String, Codable, Sendable {
        case firstPartner
        case secondPartner
    }

    /// Anonymous, client-generated identity — no email, no phone, no name.
    let userID: String
    let role: Role
    let pairID: String?
}

nonisolated struct PairRecord: Equatable, Sendable, Codable {
    let pairID: String
    var members: [CoupleMembership]
    let createdAt: Date

    var isPaired: Bool { members.count == 2 }

    /// Authorization rule used by every backend policy:
    /// a member belongs to exactly one pair and holds exactly one role in it.
    func membership(of userID: String) -> CoupleMembership? {
        members.first { $0.userID == userID }
    }
}

nonisolated struct HandOffNote: Equatable, Sendable, Codable {
    let id: String
    let fromUserID: String
    let toRole: CoupleMembership.Role
    let body: String       // authored deliberately by its writer
    let sentAt: Date
}

// MARK: - Local demo transport
//
// DEVELOPMENT REALITY: this simulates TWO SEPARATE DEVICES/USERS in one
// process, using isolated per-user in-memory stores. It exists so the couple
// flows, tests and demos run without a backend. It is NOT production
// networking: nothing here leaves the device, and the same-device spaces in
// EmberStore remain a demo convenience, not inter-partner privacy.

nonisolated final class LocalDemoCoupleService: CoupleService, @unchecked Sendable {

    private let lock = NSLock()
    private var pairs: [String: PairRecord] = [:]
    private var completionsByPair: [String: [CoupleMembership.Role: Set<Int>]] = [:]
    private var handOffsByPair: [String: [HandOffNote]] = [:]
    private var revokedPairs: Set<String> = []
    private var clock: @Sendable () -> Date

    init(clock: @escaping @Sendable () -> Date = { Date() }) {
        self.clock = clock
    }

    // MARK: Pairing

    func createPairingInvitation(from role: CoupleMembership.Role) async throws -> PairingInvite {
        let code = Self.generateCode()
        lock.lock()
        defer { lock.unlock() }
        return PairingInvite(code: code, role: role, expiresIn: 900)
    }

    @discardableResult
    func acceptPairing(code: String, as role: CoupleMembership.Role) async throws -> CoupleMembership {
        guard code.count == 6 else { throw CoupleError.invalidCode }

        let joiner = CoupleMembership(
            userID: "user-\(UUID().uuidString.prefix(8))",
            role: role,
            pairID: "pair-demo"
        )

        lock.lock()
        defer { lock.unlock() }

        if revokedPairs.contains(joiner.pairID!) {
            throw CoupleError.pairRevoked
        }

        var record = pairs[joiner.pairID!] ?? PairRecord(
            pairID: joiner.pairID!,
            members: [],
            createdAt: clock()
        )
        guard record.members.first(where: { $0.role == role }) == nil else {
            throw CoupleError.roleTaken
        }
        record.members.append(joiner)
        pairs[record.pairID] = record
        return joiner
    }

    nonisolated private static func generateCode() -> String {
        // Demo-grade opaque code. Production replaces this entirely via the
        // backend's invitation system.
        let alphabet = Array("ACDEFHJKLMNPRTUVWXY3479")
        return String((0..<6).map { _ in alphabet.randomElement()! })
    }

    // MARK: Shared state

    func shareDayCompletion(_ dayNumber: Int, by member: CoupleMembership) async throws {
        try requireActive(member)
        lock.lock(); defer { lock.unlock() }
        var set = completionsByPair[member.pairID!]?[member.role] ?? []
        set.insert(dayNumber)
        completionsByPair[member.pairID!, default: [:]][member.role] = set
    }

    func sendHandOff(_ note: HandOffNote, from member: CoupleMembership) async throws {
        try requireActive(member)
        // Authorship: you can only send as yourself…
        guard note.fromUserID == member.userID else { throw CoupleError.notAuthorized }
        // …and addressing: only ever to your OPPOSITE role. Nobody, ever,
        // addresses their own role — notes flow across, not back.
        guard note.toRole != member.role else { throw CoupleError.notAuthorized }
        lock.lock(); defer { lock.unlock() }
        handOffsByPair[member.pairID!, default: []].append(note)
    }

    func fetchHandOffs(for member: CoupleMembership) async throws -> [HandOffNote] {
        try requireActive(member)
        lock.lock(); defer { lock.unlock() }
        return (handOffsByPair[member.pairID!] ?? []).filter { $0.toRole == member.role }
    }

    // MARK: Revocation

    func unpair(_ pairID: String, requestedBy member: CoupleMembership) async throws {
        try requireActive(member)
        lock.lock(); defer { lock.unlock() }
        revokedPairs.insert(pairID)
        pairs.removeValue(forKey: pairID)
        handOffsByPair.removeValue(forKey: pairID)
        // Completions are kept keyed but never resolvable after revocation;
        // requireActive rejects everything for a revoked pair.
    }

    // MARK: Helpers

    private func requireActive(_ member: CoupleMembership) throws {
        guard member.pairID != nil else { throw CoupleError.unpaired }
        lock.lock(); defer { lock.unlock() }
        guard !revokedPairs.contains(member.pairID!) else { throw CoupleError.pairRevoked }
        guard let record = pairs[member.pairID!],
              let own = record.membership(of: member.userID),
              own.role == member.role else {
            throw CoupleError.notAuthorized
        }
    }
}

// MARK: - Errors

nonisolated enum CoupleError: Error, Equatable, Sendable {
    case invalidCode
    case roleTaken
    case unpaired
    case pairRevoked
    case notAuthorized
}
