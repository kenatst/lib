import Foundation

// MARK: - EmberStore
//
// The single owner of everything EMBER persists. All data is highly sensitive:
//  * stored in Application Support (never synced, never backed up to iCloud)
//  * complete file protection (.completeFileProtection) — unreadable when the
//    device is locked
//  * no logging of content, ever
//  * explicit deletion API used by Settings ("Delete everything")
//
// Load semantics are explicit, never `try?`:
//  * FILE ABSENT      → legitimate fresh install; initialize empty (writable)
//  * FILE READABLE    → decode + migrate normally (writable)
//  * FILE UNREADABLE  → present but locked/protected/IO-blocked. Nothing on
//                       disk is touched — no quarantine, no reset, no writes.
//                       Persistence reports .unavailable until a real read
//                       succeeds.
//  * FILE CORRUPT     → decodable data destroyed by something other than
//                       protection; quarantine (keep the bytes) and start
//                       empty but REFUSE writes until the user is told.

@MainActor
@Observable
final class EmberStore {

    // MARK: Persisted state

    nonisolated struct PersistedState: Codable, Equatable, Sendable {
        /// Bump on any breaking model change; migrate in `load`.
        var schemaVersion: Int = 4
        /// Adult-content confirmation (18+), set once on first launch.
        var ageConfirmed: Bool = false
        var intention: DesireIntention?
        var responses: Onboarding.Responses?
        var profile: DesireProfile?
        var completedDays: [Int] = []
        var checkIns: [CheckIn] = []
        /// Private reflections keyed by space ("p1"/"p2"/"solo") and day.
        /// Stays on this device only; each partner's entries are invisible
        /// to the other's space. LEGACY: day-numbered (pre-daily-engine).
        var reflectionsBySpace: [String: [Int: String]] = [:]
        /// Ongoing-engine reflections keyed by space and SESSION ID.
        /// New entries land here; legacy day-numbered entries remain intact.
        var sessionReflectionsBySpace: [String: [String: String]] = [:]
        /// Legacy (pre-couple) single-space reflections, migrated on load.
        var reflections: [Int: String] = [:]
        /// Couple mode: which partner holds this space.
        var coupleRole: CoupleRole?
        /// Partner One's handed-off note for Partner Two, and vice versa.
        /// Written ONLY by an explicit user hand-off action; never automatic.
        var handedOffNotes: [CoupleRole: String] = [:]
        /// Opt-in daily reminder (24h clock). nil = reminders off.
        var reminderHour: Int?
        var reminderMinute: Int = 20
        /// Unsaved in-progress reflections keyed by "<space>:day.<n>".
        var drafts: [String: String] = [:]

        // MARK: Daily Engine (v4) — ongoing daily guide

        /// Frozen plans by plan ID ("<localDay>#<intention>"). Today's plan
        /// lives here; it is NEVER regenerated once present.
        var dailyPlans: [String: DailyPlan] = [:]
        /// Ongoing session history — what actually happened each day.
        var sessionHistory: [DailySessionRecord] = []
        /// Slow-moving learned signals per theme (the evolving profile).
        var learnedSignals: LearnedSignals = .empty
        /// Number of completed daily sessions charged against the free
        /// allowance. Never resets on its own; a calendar day cannot refill it.
        var freeSessionsUsed: Int = 0

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

    // MARK: Persistence status

    /// Why persistence might be temporarily unable to honor writes.
    nonisolated enum UnavailabilityReason: Equatable, Sendable {
        /// The state file exists but could not be read (device locked,
        /// protection class, transient IO). No disk mutation is safe yet.
        case unreadable
        /// The state file existed but its contents were undecodable; the
        /// bytes were preserved in a quarantine file. Writes stay blocked
        /// until the situation has been surfaced to the user.
        case corruptQuarantined
    }

    /// Explicit persistence status. Features never guess whether storage
    /// is writable — they render from this.
    ///
    /// Invariant #3 (release): a FAILED WRITE must be visible. `.ready` may
    /// only be reported after a write that actually reached durable storage
    /// (or a load that proved storage works). After any failed write the
    /// status becomes `.volatile`: in-memory state stays authoritative for
    /// THIS session and every later mutation retries the disk — but the UI
    /// must never claim "saved on device" while volatile.
    nonisolated enum PersistenceStatus: Equatable, Sendable {
        case ready
        /// Last write failed; content lives in memory only until the next
        /// successful mutation persists it.
        case volatile
        case unavailable(UnavailabilityReason)
    }

    /// Truthful deletion outcome.
    nonisolated enum DeletionOutcome: Equatable, Sendable {
        case deleted
        case failed
    }

    // MARK: Observable state

    private(set) var state: PersistedState
    private(set) var persistenceStatus: PersistenceStatus = .ready

    // MARK: Storage

    nonisolated static let fileName = "ember-state.json"
    nonisolated static let quarantineSuffix = ".unreadable"
    private let directory: URL
    private let files: any FileOperating
    /// Calendar for local-day identity. Injected so tests can simulate
    /// midnight crossings, DST boundaries and timezone travel deterministically.
    private let calendar: Calendar

    var hasJourney: Bool { state.intention != nil }

    init(directory: URL? = nil, files: (any FileOperating)? = nil, calendar: Calendar? = nil) {
        self.directory = directory ?? Self.defaultDirectory()
        self.files = files ?? DefaultFileOperator()
        self.calendar = calendar ?? .current
        let outcome = Self.loadState(from: self.directory, files: self.files)
        // Unreadable/corrupt starts hold an empty PLACEHOLDER in memory only;
        // every write path is blocked until a real load succeeds.
        self.state = outcome.state ?? .empty
        switch outcome.status {
        case .ready, .volatile:
            Self.markReady(self)
        case .unavailable(let reason):
            Self.markUnavailable(self, reason)
        }
    }

    private nonisolated static func markReady(_ store: EmberStore) {
        MainActor.assumeIsolated {
            store.persistenceStatus = .ready
        }
    }

    private nonisolated static func markUnavailable(_ store: EmberStore, _ reason: UnavailabilityReason) {
        MainActor.assumeIsolated {
            store.persistenceStatus = .unavailable(reason)
        }
    }

    /// Recovery attempt after an UNAVAILABLE start (device was locked at
    /// launch and has since been unlocked). Re-reads from disk; if the real
    /// state becomes readable it replaces whatever in-memory placeholder is
    /// present, so nothing the user did while locked is written over it.
    ///
    /// RELEASE INVARIANT (write truth): .volatile memory is AUTHORITATIVE —
    /// it holds user content that never reached disk. Recovery therefore
    /// NEVER runs while volatile: replacing that content with stale disk data
    /// would silently destroy private writing. The volatile state heals only
    /// through the next successful mutation (save retries on every change).
    func retryLoading() {
        // Only a placeholder (unavailable start) may be wholesale-replaced.
        guard case .unavailable = persistenceStatus else { return }
        let outcome = Self.loadState(from: directory, files: files)
        if outcome.status == .ready, let recovered = outcome.state {
            // Replace the in-memory placeholder wholesale: whatever the user
            // touched while persistence was unavailable must not be written
            // over the real state that just became readable.
            state = recovered
            persistenceStatus = .ready
        } else if case .unavailable(let reason) = outcome.status {
            persistenceStatus = .unavailable(reason)
        }
    }

    /// Explicit recovery for the volatile case: re-persists the authoritative
    /// in-memory content to disk. Called when the environment signals that
    /// storage may work again (scenePhase active, network/IO restoration).
    /// Never overwrites memory with disk — the disk write is the retry.
    @discardableResult
    func retrySaving() -> Bool {
        guard case .volatile = persistenceStatus else { return persistenceStatus == .ready }
        save()
        return persistenceStatus == .ready
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

    // MARK: Reflection storage — private per space

    /// The storage key of the currently-open space.
    nonisolated static func spaceKey(role: CoupleRole?) -> String {
        switch role {
        case .partnerOne: "p1"
        case .partnerTwo: "p2"
        case nil: "solo"
        }
    }

    private var currentSpace: String { Self.spaceKey(role: state.coupleRole) }

    func saveReflection(_ text: String, day: Int) {
        var space = state.reflectionsBySpace[currentSpace] ?? [:]
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            space.removeValue(forKey: day)
        } else {
            space[day] = text
        }
        state.reflectionsBySpace[currentSpace] = space
        save()
    }

    func reflection(for day: Int) -> String? {
        state.reflectionsBySpace[currentSpace]?[day]
    }

    // MARK: Session-keyed reflections (ongoing engine)

    /// Saves a private reflection attached to a session ID (never a course
    /// number). Empty text deletes.
    func saveSessionReflection(_ text: String, sessionID: String) {
        var space = state.sessionReflectionsBySpace[currentSpace] ?? [:]
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            space.removeValue(forKey: sessionID)
        } else {
            space[sessionID] = text
        }
        state.sessionReflectionsBySpace[currentSpace] = space
        save()
    }

    func sessionReflection(for sessionID: String) -> String? {
        state.sessionReflectionsBySpace[currentSpace]?[sessionID]
    }

    /// Drafts keyed by session ID.
    func saveSessionDraft(_ text: String, sessionID: String) {
        let key = "\(currentSpace):session.\(sessionID)"
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state.drafts.removeValue(forKey: key)
        } else {
            state.drafts[key] = text
        }
        save()
    }

    func sessionDraft(for sessionID: String) -> String? {
        state.drafts["\(currentSpace):session.\(sessionID)"]
    }

    /// One journal row: either an ongoing session entry (with its calendar
    /// date) or a legacy day-numbered entry. Private to the current space.
    nonisolated struct JournalEntry: Equatable, Sendable {
        let sessionID: String?
        let legacyDayNumber: Int?
        let dateLabel: String?      // canonical yyyy-MM-dd for ongoing entries
        let text: String
    }

    /// Combined journal for the current space: ongoing sessions first
    /// (newest calendar day first), then legacy day-numbered entries.
    /// There is no API to read another space — by construction.
    var allJournalEntries: [JournalEntry] {
        var result: [JournalEntry] = []
        let planByID = state.dailyPlans
        let sessionEntries = state.sessionReflectionsBySpace[currentSpace] ?? [:]
        let sortedSessions = sessionEntries.sorted { lhs, rhs in
            let lDay = planByID[lhs.key]?.day.storageKey ?? ""
            let rDay = planByID[rhs.key]?.day.storageKey ?? ""
            return lDay > rDay
        }
        for (sessionID, text) in sortedSessions {
            result.append(JournalEntry(
                sessionID: sessionID,
                legacyDayNumber: nil,
                dateLabel: planByID[sessionID]?.day.description,
                text: text
            ))
        }
        for (day, text) in (state.reflectionsBySpace[currentSpace] ?? [:]).sorted(by: { $0.key > $1.key }) {
            result.append(JournalEntry(
                sessionID: nil,
                legacyDayNumber: day,
                dateLabel: nil,
                text: text
            ))
        }
        return result
    }

    /// Records a Return for a SPECIFIC frozen session — used when the evening
    /// stretches past midnight, so the response lands on the day the user
    /// actually experienced, not whichever day the clock now says.
    func recordCheckIn(_ checkIn: CheckIn, forSession sessionID: String) {
        state.checkIns.removeAll { $0.dayNumber == checkIn.dayNumber }
        state.checkIns.append(checkIn)
        state.checkIns.sort { $0.dayNumber < $1.dayNumber }
        if let index = state.sessionHistory.firstIndex(where: { $0.id == sessionID }) {
            state.sessionHistory[index].checkInResponse = checkIn.response
            SignalUpdater.apply(state.sessionHistory[index], to: &state.learnedSignals,
                                today: state.sessionHistory[index].day)
        }
        save()
    }

    func recordCheckIn(_ checkIn: CheckIn) {
        state.checkIns.removeAll { $0.dayNumber == checkIn.dayNumber }
        state.checkIns.append(checkIn)
        state.checkIns.sort { $0.dayNumber < $1.dayNumber }
        // The response also lands on TODAY'S history record — feeding FUTURE
        // plans only. Today's plan itself is already frozen and unaffected.
        if let planID = currentPlanID,
           let plan = state.dailyPlans[planID],
           let index = state.sessionHistory.firstIndex(where: { $0.id == plan.id }) {
            state.sessionHistory[index].checkInResponse = checkIn.response
            // LEARNED SIGNALS (production loop): fold tonight's honesty into
            // the slow-moving per-theme resonance that steers tomorrow.
            SignalUpdater.apply(state.sessionHistory[index], to: &state.learnedSignals, today: today)
        }
        save()
    }

    // MARK: Daily Engine

    /// The plan ID for today under the current intention.
    var currentPlanID: String? {
        guard let intention = state.intention else { return nil }
        return DailyEngine.planID(day: today, intention: intention)
    }

    /// Today, in the user's calendar (identity calendar injected at init).
    var today: LocalDay { LocalCalendar.day(for: Date(), in: calendar) }

    /// IDEMPOTENT today access: returns the frozen plan for today, creating
    /// it only if absent. Opening the app 20 times returns identical plans.
    @discardableResult
    func planForToday() -> DailyPlan? {
        guard let intention = state.intention else { return nil }
        let plan = DailyEngine.planForToday(
            today: today,
            intention: intention,
            profile: state.profile,
            checkIns: state.checkIns,
            plans: state.dailyPlans,
            history: state.sessionHistory,
            signals: state.learnedSignals,
            coupleRole: state.coupleRole.map {
                $0 == .partnerOne ? CoupleSpace.partnerOne : .partnerTwo
            }
        )
        if state.dailyPlans[plan.id] == nil {
            // Freeze it — first creation only.
            state.dailyPlans[plan.id] = plan
            // Record that these content units were served (cooldown bookkeeping).
            if let index = state.sessionHistory.firstIndex(where: { $0.id == plan.id }) {
                state.sessionHistory[index].servedIDs.formUnion(plan.allContentKeys)
            } else {
                state.sessionHistory.append(DailySessionRecord(
                    id: plan.id,
                    day: plan.day,
                    intention: plan.intention,
                    theme: plan.theme,
                    servedIDs: plan.allContentKeys
                ))
            }
            save()
        }
        return plan
    }

    /// Marks a movement complete on today's record. Never touches the plan.
    func markMovement(_ movement: Movement, complete: Bool = true) {
        guard let planID = currentPlanID else { return }
        if let index = state.sessionHistory.firstIndex(where: { $0.id == planID }) {
            if complete {
                state.sessionHistory[index].completedMovements.insert(movement)
            } else {
                state.sessionHistory[index].completedMovements.remove(movement)
            }
            save()
        }
    }

    /// A daily session is COMPLETE when its Act has been lived (Discover +
    /// Act minimum; Return is evening and optional). Drives free-allowance
    /// counting and history — not any finite completion.
    func completeTodaySession() {
        guard let planID = currentPlanID else { return }
        markMovement(.act)
        if let index = state.sessionHistory.firstIndex(where: { $0.id == planID }),
           !state.sessionHistory[index].completedMovements.isEmpty {
            let wasCounted = state.sessionHistory[index].completedMovements.contains(.act)
            if wasCounted && state.freeSessionsUsed < countCompletedSessions() {
                state.freeSessionsUsed = countCompletedSessions()
            }
        }
        save()
    }

    /// Sessions with a completed Act — the real "days lived" measure.
    func countCompletedSessions() -> Int {
        state.sessionHistory.filter { $0.completedMovements.contains(.act) }.count
    }

    func setAgeConfirmed() {
        state.ageConfirmed = true
        save()
    }

    func setReminder(hour: Int?, minute: Int) {
        state.reminderHour = hour
        state.reminderMinute = minute
        save()
    }

    // MARK: Drafts (in-progress reflections)

    func saveDraft(_ text: String, day: Int) {
        let key = "\(currentSpace):day.\(day)"
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state.drafts.removeValue(forKey: key)
        } else {
            state.drafts[key] = text
        }
        save()
    }

    func draft(for day: Int) -> String? {
        state.drafts["\(currentSpace):day.\(day)"]
    }

    func clearDraft(day: Int) {
        state.drafts.removeValue(forKey: "\(currentSpace):day.\(day)")
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

    /// Erases everything EMBER knows — LITERALLY everything. The EMBER
    /// Application Support directory contains only EMBER private state and
    /// recovery artifacts (state file, quarantines, timestamped recoveries,
    /// debug seeding files), so deletion removes the directory recursively.
    /// Success is VERIFIED afterwards: the directory must not exist, or exist
    /// with zero entries. In-memory state clears ONLY after verified cleanup.
    ///
    /// A failed deletion returns .failed and leaves memory untouched — the UI
    /// stays in the real journey and says so, never claiming an erasure that
    /// did not happen.
    @discardableResult
    func deleteEverything() -> DeletionOutcome {
        do {
            if files.fileExists(at: directory) {
                try files.removeItem(at: directory)
            }
        } catch {
            EmberLog.app.fault("Failed to remove EMBER data directory")
            return .failed
        }

        // VERIFY: nothing sensitive may remain. Directory absent = clean;
        // present but empty also counts (an OS can lazily recreate containers).
        // FAILS CLOSED: an unreadable listing throws → .failed, never a
        // false "clean" claim over surviving private bytes.
        if files.fileExists(at: directory) {
            let leftovers: [String]
            do {
                leftovers = try files.contentsOfDirectory(at: directory)
            } catch {
                EmberLog.app.fault("Could not verify deletion; refusing to claim success")
                return .failed
            }
            guard leftovers.isEmpty else {
                EmberLog.app.fault("Deletion left files behind; refusing to claim success")
                return .failed
            }
        }

        state = .empty
        persistenceStatus = .ready
        return .deleted
    }

    /// Erases journey progress. Same truthfulness contract as deletion.
    @discardableResult
    func restartJourney() -> DeletionOutcome {
        deleteEverything()
    }

    // MARK: Saving

    private func save() {
        if case .unavailable = persistenceStatus {
            // Never overwrite a file we could not read, and never write over
            // quarantined data before the user has seen what happened.
            // Temporary inability to save always beats destroying private writing.
            EmberLog.app.fault("Refusing to save while persistence is unavailable")
            return
        }
        do {
            try files.createDirectory(at: directory)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(state)
            try files.write(data, to: directory.appendingPathComponent(Self.fileName))
            // Durable success — including recovery from a previous failure.
            persistenceStatus = .ready
        } catch {
            // Never log content. The failure is surfaced through the status:
            // the UI must not claim a durable save while volatile.
            persistenceStatus = .volatile
            EmberLog.app.fault("Failed to persist state")
        }
    }

    // MARK: Loading — explicit, never `try?`

    nonisolated struct LoadOutcome: Equatable, Sendable {
        let state: PersistedState?
        let status: PersistenceStatus
    }

    nonisolated private static func loadState(from directory: URL, files: any FileOperating) -> LoadOutcome {
        let url = directory.appendingPathComponent(fileName)

        // 1. Absent → legitimate fresh install. Safe to initialize.
        guard files.fileExists(at: url) else {
            return LoadOutcome(state: .empty, status: .ready)
        }

        // 2. Present → READ it explicitly. Distinguish "cannot read" (locked,
        //    protection, IO) from "read but undecodable" (corruption).
        let data: Data
        do {
            data = try files.readData(at: url)
        } catch {
            // PRESENT + TEMPORARILY UNREADABLE: touch NOTHING on disk.
            // No overwrite, no quarantine, no reset. Persistence stays
            // unavailable until the file can genuinely be read again.
            EmberLog.app.fault("State file exists but is unreadable; refusing all writes")
            return LoadOutcome(state: nil, status: .unavailable(.unreadable))
        }

        // 3. Readable → decode + migrate.
        if var decoded = try? JSONDecoder().decode(PersistedState.self, from: data) {
            applyMigrations(to: &decoded)
            return LoadOutcome(state: decoded, status: .ready)
        }

        // 4. PRESENT + ACTUALLY CORRUPT: preserve every byte in a quarantine
        //    file (recoverable), never destroy. Writes stay blocked until the
        //    situation has been surfaced — an empty default must not silently
        //    replace a broken-but-real history.
        let backupURL = directory.appendingPathComponent(fileName + quarantineSuffix)
        if files.fileExists(at: backupURL) {
            // Keep earlier quarantines distinguishable instead of destroying them.
            let stamp = Int(Date().timeIntervalSince1970)
            _ = try? files.moveItem(at: url, to: directory.appendingPathComponent("\(fileName).quarantine-\(stamp)"))
        } else {
            _ = try? files.moveItem(at: url, to: backupURL)
        }
        EmberLog.app.fault("State file undecodable; quarantined without destruction")
        return LoadOutcome(state: nil, status: .unavailable(.corruptQuarantined))
    }

    /// Schema migrations, oldest → current. Pure, ordered and IDEMPOTENT:
    /// running twice yields the same state as running once.
    nonisolated static func applyMigrations(to state: inout PersistedState) {
        // v1→v3: legacy single-space reflections move into their owner's
        // space. MERGES rather than replaces — if a newer field already has
        // content (e.g. a partially migrated file), legacy entries are still
        // carried over instead of being stranded invisible.
        if !state.reflections.isEmpty {
            let space = spaceKey(role: state.coupleRole)
            var target = state.reflectionsBySpace[space] ?? [:]
            for (day, text) in state.reflections where target[day] == nil {
                target[day] = text
            }
            state.reflectionsBySpace[space] = target
            state.reflections = [:]
        }

        // v3→v4 (Daily Engine): the finite 21-day course becomes an ongoing
        // daily guide. Legacy numbered history is preserved HONESTLY as
        // session records flagged with their legacy day number — no invented
        // calendar dates. Check-ins migrate onto the same records so learned
        // signals can be seeded from real history without fabrication.
        if state.schemaVersion < 4 {
            if let intention = state.intention {
                let existingIDs = Set(state.sessionHistory.map(\.id))
                // Order preserved: check-ins stay attached to their day.
                // Tolerate corrupt/duplicated persisted input: never trap.
                let responsesByDay = Dictionary(
                    state.checkIns.map { ($0.dayNumber, $0.response) },
                    uniquingKeysWith: { _, new in new }
                )
                for dayNumber in state.completedDays.sorted() where dayNumber >= 1 && dayNumber <= 21 {
                    let theme = JourneyShape.shape(for: intention)
                        .theme(for: dayNumber)
                    let id = "legacy-day.\(dayNumber)#\(intention.rawValue)"
                    guard !existingIDs.contains(id) else { continue }
                    state.sessionHistory.append(DailySessionRecord(
                        id: id,
                        day: legacyAnchorDay(offset: dayNumber - 1),
                        intention: intention,
                        theme: theme,
                        servedIDs: [],
                        completedMovements: [.discover, .reflect, .act],
                        checkInResponse: responsesByDay[dayNumber],
                        legacyDayNumber: dayNumber
                    ))
                }
            }
            // Seed the free-allowance counter from lived sessions so an
            // existing user is not accidentally reset to "brand new free".
            if state.freeSessionsUsed < state.completedDays.count {
                state.freeSessionsUsed = state.completedDays.count
            }
            // Seed learned signals from migrated history (bounded, slow).
            if state.learnedSignals == .empty {
                var signals = LearnedSignals.empty
                let today = LocalCalendar.today(in: .current)
                for record in state.sessionHistory {
                    SignalUpdater.apply(record, to: &signals, today: today)
                }
                state.learnedSignals = signals
            }
        }

        state.schemaVersion = PersistedState.empty.schemaVersion
    }

    /// Honest anchor for legacy records: the epoch of the daily engine, plus
    /// the legacy position. These dates say "on or before launch of the
    /// ongoing engine", never a claimed real calendar day. Deterministic;
    /// ordering by legacy number is preserved.
    private nonisolated static func legacyAnchorDay(offset: Int) -> LocalDay {
        let base = LocalDay.unchecked("2026-01-01")
        var day = base
        for _ in 0..<max(0, offset) { day = day.next() }
        return day
    }
}

// MARK: - File operations seam
//
// Deliberately tiny: just enough surface to test absence/unreadability/
// corruption/deletion-failure deterministically without a filesystem framework.

nonisolated protocol FileOperating: Sendable {
    func fileExists(at url: URL) -> Bool
    func readData(at url: URL) throws -> Data
    func write(_ data: Data, to url: URL) throws
    func createDirectory(at url: URL) throws
    func removeItem(at url: URL) throws
    func moveItem(at url: URL, to url2: URL) throws
    /// Names of entries in the directory (used to verify deletion success).
    /// Throws on IO/permission errors — deletion verification FAILS CLOSED:
    /// an unreadable listing must never be treated as "empty = clean".
    func contentsOfDirectory(at url: URL) throws -> [String]
}

nonisolated struct DefaultFileOperator: FileOperating {
    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
    func readData(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        // Keep EMBER data out of any device backup — it lives here only.
        var mutableURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        _ = try? mutableURL.setResourceValues(values)
    }
    func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    func removeItem(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    func moveItem(at url: URL, to destination: URL) throws {
        try FileManager.default.moveItem(at: url, to: destination)
    }
    func contentsOfDirectory(at url: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: url.path)
    }
}
