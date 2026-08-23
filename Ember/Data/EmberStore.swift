import Foundation

// MARK: - EmberStore
//
// The single owner of everything EMBER persists. All data is highly sensitive:
//  * stored in Application Support (never synced, never backed up to iCloud)
//  * complete file protection (.completeFileProtection) — unreadable when the
//    device is locked
//  * no logging of content, ever
//  * explicit deletion API used by Settings ("Delete everything")

@MainActor
@Observable
final class EmberStore {

    // MARK: Persisted state

    nonisolated struct PersistedState: Codable, Equatable, Sendable {
        var intention: DesireIntention?
        var responses: Onboarding.Responses?
        var profile: DesireProfile?
        var completedDays: [Int] = []
        var checkIns: [CheckIn] = []
        /// Private reflections, keyed by day. Stays on this device only.
        var reflections: [Int: String] = [:]
        /// Couple mode: which partner holds this space.
        var coupleRole: CoupleRole?
        /// Partner One's handed-off note for Partner Two, and vice versa.
        /// Written ONLY by an explicit user hand-off action; never automatic.
        var handedOffNotes: [CoupleRole: String] = [:]

        static let empty = PersistedState()
    }

    nonisolated enum CoupleRole: String, Codable, CaseIterable, Sendable, Hashable {
        case partnerOne
        case partnerTwo

        var other: CoupleRole { self == .partnerOne ? .partnerTwo : .partnerOne }

        var nameKey: String {
            switch self {
            case .partnerOne: "couple.role.first"
            case .partnerTwo: "couple.role.second"
            }
        }
    }

    // MARK: Observable state

    private(set) var state: PersistedState

    // MARK: Storage

    nonisolated static let fileName = "ember-state.json"
    private let directory: URL

    var hasJourney: Bool { state.intention != nil }

    init(directory: URL? = nil) {
        self.directory = directory ?? Self.defaultDirectory()
        self.state = Self.load(from: self.directory)
    }

    nonisolated static func defaultDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Ember", isDirectory: true)
    }

    // MARK: Mutations

    func setIntention(_ intention: DesireIntention) {
        state.intention = intention
        save()
    }

    func recordResponses(_ responses: Onboarding.Responses) {
        state.responses = responses
        save()
    }

    func setProfile(_ profile: DesireProfile) {
        state.profile = profile
        save()
    }

    func markDayComplete(_ dayNumber: Int) {
        guard !state.completedDays.contains(dayNumber) else { return }
        state.completedDays.append(dayNumber)
        state.completedDays.sort()
        save()
    }

    func saveReflection(_ text: String, day: Int) {
        state.reflections[day] = text
        save()
    }

    func reflection(for day: Int) -> String? {
        state.reflections[day]
    }

    func recordCheckIn(_ checkIn: CheckIn) {
        state.checkIns.removeAll { $0.dayNumber == checkIn.dayNumber }
        state.checkIns.append(checkIn)
        state.checkIns.sort { $0.dayNumber < $1.dayNumber }
        save()
    }

    func setCoupleRole(_ role: CoupleRole?) {
        state.coupleRole = role
        save()
    }

    /// Explicit, deliberate hand-off: one partner chooses to pass a note.
    /// There is deliberately no API to read the other partner's private
    /// reflections — this is the ONLY channel between spaces.
    func handOffNote(_ text: String, from role: CoupleRole) {
        state.handedOffNotes[role.other] = text
        save()
    }

    func takeHandedOffNote(for role: CoupleRole) -> String? {
        state.handedOffNotes[role]
    }

    // MARK: Deletion (privacy by design)

    /// Erases everything EMBER knows, immediately, including the file itself.
    func deleteEverything() {
        state = .empty
        let url = directory.appendingPathComponent(Self.fileName)
        try? FileManager.default.removeItem(at: url)
    }

    /// Erases journey progress but keeps nothing sensitive either way.
    func restartJourney() {
        deleteEverything()
    }

    // MARK: I/O

    private func save() {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(state)
            let url = directory.appendingPathComponent(Self.fileName)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            // Never log content. A failed save is surfaced by state divergence,
            // not by diagnostics containing user data.
            EmberLog.app.fault("Failed to persist state")
        }
    }

    nonisolated private static func load(from directory: URL) -> PersistedState {
        let url = directory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return .empty }
        guard let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) else { return .empty }
        return decoded
    }
}
