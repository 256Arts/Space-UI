//
//  LayoutThatFits.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2022-09-16.
//  Copyright © 2022 256 Arts Developer. All rights reserved.
//

import SwiftUI

/// Creates a layout using the first layout that fits in the axes provided from the array of layout preferences
struct LayoutThatFits: Layout {
    
    let axes: Axis.Set
    let layoutPreferences: [AnyLayout]
    
    /// Creates a layout using the first layout that fits in the axes provided from the array of layout preferences
    /// - Parameters:
    ///   - axes: Axes this content must fit in.
    ///   - layoutPreferences: Layout preferences from largest to smallest.
    init(in axes: Axis.Set = [.horizontal, .vertical], _ layoutPreferences: [any Layout]) {
        self.axes = axes
        self.layoutPreferences = layoutPreferences.map { AnyLayout($0) }
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let layout = layoutThatFits(proposal: proposal, subviews: subviews, cache: &cache) ?? layoutPreferences.first else { return CGSize(width: 10, height: 10) }
        var cache = layout.makeCache(subviews: subviews)
        return layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let layout = layoutThatFits(proposal: proposal, subviews: subviews, cache: &cache) ?? layoutPreferences.first else { return }
        var cache = layout.makeCache(subviews: subviews)
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
    
    private func layoutThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> AnyLayout? {
        layoutPreferences.first(where: { layout in
            var cache = layout.makeCache(subviews: subviews)
            let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
            
            let widthFits = size.width <= (proposal.width ?? .infinity)
            let heightFits = size.height <= (proposal.height ?? .infinity)
            
            return (widthFits || !axes.contains(.horizontal)) && (heightFits || !axes.contains(.vertical))
        })
    }
}
