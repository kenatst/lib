import CoreGraphics

/// Semantic spacing scale. Generous by design — negative space is part of the
/// editorial identity. Never use raw numbers in features.
enum Spacing {
    /// 8 — inside components
    static let xs: CGFloat = 8
    /// 16 — between related elements
    static let sm: CGFloat = 16
    /// 24 — between blocks
    static let md: CGFloat = 24
    /// 32 — section rhythm
    static let lg: CGFloat = 32
    /// 48 — breath / page margins for hero moments
    static let xl: CGFloat = 48
    /// 64 — chapter breaks
    static let xxl: CGFloat = 64
}
