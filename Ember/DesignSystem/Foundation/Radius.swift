import CoreGraphics

/// Corner radii. EMBER favors gentle, mostly-rectangular geometry — large
/// radii read "generic card UI", so caps stay restrained.
enum Radius {
    /// 6 — small marks, chips
    static let sm: CGFloat = 6
    /// 14 — inputs, inline surfaces
    static let md: CGFloat = 14
    /// 22 — primary buttons and panels
    static let lg: CGFloat = 22
    /// 999 - capsule (used only for tiny progress dots)
    static let capsule: CGFloat = 999
}

extension Radius {
    static let pill: CGFloat = capsule
}
