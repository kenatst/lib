nonisolated enum DesireIntention: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case myDesire
    case theirDesire
    case ourDesire

    var id: String { rawValue }
}
