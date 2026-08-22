extension DesireIntention {

    var displayName: String {
        switch self {
        case .myDesire: String(localized: "intention.myDesire.name")
        case .theirDesire: String(localized: "intention.theirDesire.name")
        case .ourDesire: String(localized: "intention.ourDesire.name")
        }
    }

    var tagline: String {
        switch self {
        case .myDesire: String(localized: "intention.myDesire.tagline")
        case .theirDesire: String(localized: "intention.theirDesire.tagline")
        case .ourDesire: String(localized: "intention.ourDesire.tagline")
        }
    }
}
