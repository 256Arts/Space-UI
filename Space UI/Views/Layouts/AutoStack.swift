import SwiftUI

/// A stack layout that picks the axis (horizontal or vertical) that best fits the proposed aspect ratio.
struct AutoStack: Layout {

    /// Everything about a layout pass that doesn't depend on the proposal.
    ///
    /// Both candidate stacks and the two ideal sizes the axis choice compares are built once per pass
    /// instead of once in `sizeThatFits` and again in `placeSubviews`.
    struct Cache {
        let horizontalLayout: AnyLayout
        let verticalLayout: AnyLayout
        var horizontalCache: AnyLayout.Cache
        var verticalCache: AnyLayout.Cache
        /// The size an HStack of the subviews wants at their ideal sizes.
        let hStackSize: CGSize
        /// The size a VStack of the subviews wants at their ideal sizes.
        let vStackSize: CGSize
    }

    let spacing: CGFloat?

    init(spacing: CGFloat? = nil) {
        self.spacing = spacing
    }

    func makeCache(subviews: Subviews) -> Cache {
        let horizontalLayout = AnyLayout(HStackLayout(spacing: spacing))
        let verticalLayout = AnyLayout(VStackLayout(spacing: spacing))
        var hStackSize = CGSize.zero
        var vStackSize = CGSize.zero
        for subview in subviews {
            let size = subview.idealSize
            hStackSize = CGSize(
                width: hStackSize.width + size.width,
                height: max(hStackSize.height, size.height))
            vStackSize = CGSize(
                width: max(vStackSize.width, size.width),
                height: vStackSize.height + size.height)
        }
        return Cache(
            horizontalLayout: horizontalLayout,
            verticalLayout: verticalLayout,
            horizontalCache: horizontalLayout.makeCache(subviews: subviews),
            verticalCache: verticalLayout.makeCache(subviews: subviews),
            hStackSize: hStackSize,
            vStackSize: vStackSize)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        switch optimalAxis(proposal: proposal, cache: cache) {
        case .horizontal:
            return cache.horizontalLayout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache.horizontalCache)
        case .vertical:
            return cache.verticalLayout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache.verticalCache)
        }
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        switch optimalAxis(proposal: proposal, cache: cache) {
        case .horizontal:
            cache.horizontalLayout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache.horizontalCache)
        case .vertical:
            cache.verticalLayout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache.verticalCache)
        }
    }

    private func optimalAxis(proposal: ProposedViewSize, cache: Cache) -> Axis {
        switch (cache.hStackSize.width, cache.hStackSize.height) {
        case (.infinity, .infinity):
            let proposalIsLandscape = proposal.height ?? 0 <= proposal.width ?? 0
            return proposalIsLandscape ? .horizontal : .vertical
        case (.infinity, _):
            return .vertical
        case (_, .infinity):
            return .horizontal
        default:
            let hStackRatioDifference = aspectRatioDifference(cache.hStackSize, proposal.aspectRatio)
            let vStackRatioDifference = aspectRatioDifference(cache.vStackSize, proposal.aspectRatio)
            return hStackRatioDifference < vStackRatioDifference ? .horizontal : .vertical
        }
    }
}
