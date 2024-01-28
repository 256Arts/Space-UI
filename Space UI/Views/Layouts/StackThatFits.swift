//
//  StackThatFits.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-09-16.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

/// Creates a stack layout that best fits the proposed aspect ratio
struct StackThatFits: Layout {
    
    let spacing: CGFloat?
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let layout = optimalLayout(proposal: proposal, subviews: subviews)
        var cache = layout.makeCache(subviews: subviews)
        return layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = optimalLayout(proposal: proposal, subviews: subviews)
        var cache = layout.makeCache(subviews: subviews)
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
    
    private func optimalLayout(proposal: ProposedViewSize, subviews: Subviews) -> AnyLayout {
        switch optimalAxis(proposal: proposal, subviews: subviews) {
        case .vertical:
            return AnyLayout(VStackLayout(spacing: spacing))
        case .horizontal:
            return AnyLayout(HStackLayout(spacing: spacing))
        }
    }
    
    private func optimalAxis(proposal: ProposedViewSize, subviews: Subviews) -> Axis {
        let hStackSize = subviews.reduce(CGSize.zero) { result, subview in
            let size = subview.idealSize
            return CGSize(
                width: result.width + size.width,
                height: max(result.height, size.height))
        }
        let vStackSize = subviews.reduce(CGSize.zero) { result, subview in
            let size = subview.idealSize
            return CGSize(
                width: max(result.width, size.width),
                height: result.height + size.height)
        }
        
        let axis: Axis = {
            switch (hStackSize.width, hStackSize.height) {
            case (.infinity, .infinity):
                let proposalIsLandscape = proposal.height ?? 0 <= proposal.width ?? 0
                return proposalIsLandscape ? .horizontal : .vertical
            case (.infinity, _):
                return .vertical
            case (_, .infinity):
                return .horizontal
            default:
                let hStackRatioDifference = aspectRatioDifference(hStackSize, proposal.aspectRatio)
                let vStackRatioDifference = aspectRatioDifference(vStackSize, proposal.aspectRatio)
                return hStackRatioDifference < vStackRatioDifference ? .horizontal : .vertical
            }
        }()
        return axis
    }
}
