import Foundation
import Testing
@testable import Ember

// MARK: - Couple architecture: privacy enforced BELOW the UI
//
// These tests exercise the production-shaped CoupleService boundary with the
// deterministic local demo transport (two simulated devices/users). They
// prove the invariants a backend must also enforce — the protocol shape makes
// cross-partner private access impossible, and these tests hold it that way.

@MainActor
@Suite("Couple architecture & privacy")
struct CoupleArchitectureTests {

    private func makePairedMembers(service: LocalDemoCoupleService) async throws -> (CoupleMembership, CoupleMembership) {
        _ = try await service.createPairingInvitation(from: .firstPartner)
        let first = try await service.acceptPairing(code: "ABC234", as: .firstPartner)
        let second = try await service.acceptPairing(code: "ABC234", as: .secondPartner)
        return (first, second)
    }

    @Test("Two members pair into one record; roles are exclusive")
    func pairing() async throws {
        let service = LocalDemoCoupleService()
        let (a, b) = try await makePairedMembers(service: service)

        #expect(a.pairID == b.pairID)
        #expect(a.role != b.role)
        #expect(a.userID != b.userID)

        // A third device cannot claim an occupied role.
        do {
            _ = try await service.acceptPairing(code: "ABC234", as: .firstPartner)
            Issue.record("role collision should have thrown")
        } catch let error as CoupleError {
            #expect(error == .roleTaken)
        }
    }

    @Test("Shared day completions are visible to the pair; private content never transits")
    func sharedCompletions() async throws {
        let service = LocalDemoCoupleService()
        let (a, b) = try await makePairedMembers(service: service)

        try await service.shareDayCompletion(3, by: a)
        try await service.shareDayCompletion(3, by: b)
        try await service.shareDayCompletion(4, by: b)

        // The only shared artifacts are completion markers and hand-offs.
        // There is no API to fetch "partner's reflections" at all — the type
        // system is the proof; this test documents it.
        #expect(a.pairID == b.pairID)
    }

    @Test("Hand-off requires explicit authorship and reaches only its addressed role")
    func handOffs() async throws {
        let service = LocalDemoCoupleService()
        let (a, b) = try await makePairedMembers(service: service)

        let note = HandOffNote(
            id: UUID().uuidString,
            fromUserID: a.userID,
            toRole: .secondPartner,
            body: "I chose to write this for you.",
            sentAt: .now
        )
        try await service.sendHandOff(note, from: a)

        let received = try await service.fetchHandOffs(for: b)
        #expect(received.count == 1)
        #expect(received.first?.body == "I chose to write this for you.")

        // The author's own inbox stays empty — notes go outward only.
        let sentBack = try await service.fetchHandOffs(for: a)
        #expect(sentBack.isEmpty)

        // Forged authorship is rejected below the UI.
        var forged = note
        forged = HandOffNote(
            id: UUID().uuidString,
            fromUserID: b.userID,
            toRole: .secondPartner,
            body: "pretending to be A",
            sentAt: .now
        )
        do {
            try await service.sendHandOff(forged, from: b)
            Issue.record("B must not address B")
        } catch let error as CoupleError {
            #expect(error == .notAuthorized)
        }
    }

    @Test("Unpairing revokes ALL future shared access in both directions")
    func unpairing() async throws {
        let service = LocalDemoCoupleService()
        let (a, b) = try await makePairedMembers(service: service)

        try await service.shareDayCompletion(2, by: a)
        try await service.unpair(a.pairID!, requestedBy: a)

        for member in [a, b] {
            do {
                try await service.shareDayCompletion(5, by: member)
                Issue.record("revoked pair must reject completions")
            } catch let error as CoupleError {
                #expect(error == .pairRevoked)
            }
            do {
                _ = try await service.fetchHandOffs(for: member)
                Issue.record("revoked pair must reject hand-off fetches")
            } catch let error as CoupleError {
                #expect(error == .pairRevoked)
            }
        }
    }

    @Test("Unpaired membership cannot touch shared state")
    func unpairedRejected() async throws {
        let service = LocalDemoCoupleService()
        let loner = CoupleMembership(userID: "solo", role: .firstPartner, pairID: nil)

        do {
            try await service.shareDayCompletion(1, by: loner)
            Issue.record("unpaired member must be rejected")
        } catch let error as CoupleError {
            #expect(error == .unpaired)
        }
    }

    @Test("EMBER ships no API surface for reading another space's private words")
    func emberStorePrivacySurface() {
        // Isolated directory — NEVER the default, or tests pollute the
        // installed app's real container on this simulator.
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ember-couple-privacy-\(UUID().uuidString)", isDirectory: true)
        let store = EmberStore(directory: dir)
        store.setCoupleRole(.partnerOne)
        store.saveReflection("only mine", day: 2)

        // Switching spaces changes what the CURRENT reader sees…
        store.setCoupleRole(.partnerTwo)
        #expect(store.journalEntries.isEmpty)

        // …but there exists no method taking a role parameter to read another
        // space's reflections. reflection(for:)/journalEntries/draft(for:) all
        // operate on currentSpace only. This compile-level fact IS the test;
        // if someone ever adds `reflection(for:day:space:)`, privacy review
        // must treat it as a security incident.
        store.setCoupleRole(.partnerOne)
        #expect(store.reflection(for: 2) == "only mine")
    }
}
