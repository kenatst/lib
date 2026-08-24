import Foundation

// MARK: - DailyPlan
//
// THE FROZEN CONTRACT for one calendar day.
//
// Created ONCE by the DailyEngine the first time the user opens EMBER on a
// given local day, then immutable forever: reflections, completions, evening
// check-ins and app restarts can never change what a plan contains. A
// response given tonight shapes TOMORROW's plan — never today's.
//
// Persisted as stable IDs only; localization resolves at render time.

nonisolated struct DailyPlan: Equatable, Identifiable, Sendable, Codable {
    /// Deterministic ID: "<localDay>#<intention>" — one canonical plan per
    /// day per journey.
    let id: String
    /// The canonical local calendar day this experience belongs to.
    let day: LocalDay
    let intention: DesireIntention
    /// The session's unifying theme — the whole day is ONE idea.
    let theme: DayTheme
    /// Stable content IDs for each movement.
    let titleContentID: ContentID
    let discoverContentID: ContentID
    let reflectContentID: ContentID
    let actContentID: ContentID
    let returnPromptID: ContentID
    /// The dose at planning time (frozen with the plan).
    let intensity: DailyEngine.Intensity
    /// Themes the personalization engine was emphasizing when frozen.
    let emphasizedThemes: [DayTheme]
    /// OUR DESIRE: asymmetric assignments per partner role, by stable ID.
    var coupleAssignmentIDs: [CoupleSpace: ContentID]?
    /// When this plan was frozen (diagnostics; never drives logic).
    let createdAt: Date

    /// All content IDs in one set — history/cooldown bookkeeping.
    var allContentKeys: Set<String> {
        var keys: Set<String> = [titleContentID.key, discoverContentID.key,
                                 reflectContentID.key, actContentID.key, returnPromptID.key]
        if let assignments = coupleAssignmentIDs {
            for value in assignments.values {
                keys.insert(value.key)
            }
        }
        return keys
    }
}

// MARK: - DailySessionRecord

/// What actually happened on a day — written progressively through the day,
/// but never altering the PLAN. History, not control.
nonisolated struct DailySessionRecord: Equatable, Identifiable, Sendable, Codable {
    let id: String                 // same scheme as DailyPlan.id
    let day: LocalDay
    let intention: DesireIntention
    let theme: DayTheme
    /// Every content ID shown this day (for cooldowns).
    var servedIDs: Set<String>
    /// Which movements were completed.
    var completedMovements: Set<Movement>
    /// The evening Return result, if given.
    var checkInResponse: CheckInResponse?
    /// Legacy numbered-session mapping (v3 migration). nil for native days.
    var legacyDayNumber: Int?

    init(id: String, day: LocalDay, intention: DesireIntention, theme: DayTheme,
         servedIDs: Set<String> = [], completedMovements: Set<Movement> = [],
         checkInResponse: CheckInResponse? = nil, legacyDayNumber: Int? = nil) {
        self.id = id
        self.day = day
        self.intention = intention
        self.theme = theme
        self.servedIDs = servedIDs
        self.completedMovements = completedMovements
        self.checkInResponse = checkInResponse
        self.legacyDayNumber = legacyDayNumber
    }
}
