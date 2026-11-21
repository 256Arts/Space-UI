import Testing
import CoreGraphics
import SwiftUI
@testable import Space_UI

/// Guards the W6.2 cutout refactor: the reported cutout frame (`cutoutFrame`, used to place content inside a
/// screen cutout) must agree with what `ScreenShape.path` actually draws. These used to re-derive the numbers
/// separately and had drifted (different corner-radius floor and content-width caps). Both now share
/// `ScreenStyles.cutoutLayout`, and these tests keep them in lockstep — and pin the drawn-path formula so the
/// remaining W6.2 geometry fold can't silently change it.
@MainActor
struct CutoutGeometryTests {

    private static let sizes: [CGSize] = [
        CGSize(width: 800, height: 1_200),
        CGSize(width: 1_200, height: 1_600),
        CGSize(width: 1_600, height: 900),
        CGSize(width: 2_400, height: 1_080)
    ]

    @Test(arguments: TestSeeds.sweep)
    func reportedCutoutFrameMatchesLayout(seed: UInt64) {
        let system = SystemStyles(config: .seedOnly(seed))
        let styles = system.screen
        for size in Self.sizes {
            let layout = styles.cutoutLayout(rect: CGRect(origin: .zero, size: size), insetAmount: 0, screenShapeType: styles.resolvedScreenShapeType(screenSize: size), system: system)
            if let top = styles.cutoutFrame(screenSize: size, forTop: true, system: system) {
                #expect(approxEqual(top.width, layout.cutoutContentWidth))
                #expect(approxEqual(top.height, layout.cutoutHeight))
                #expect(top.minY == 0)
            }
            if let bottom = styles.cutoutFrame(screenSize: size, forTop: false, system: system) {
                #expect(approxEqual(bottom.width, layout.cutoutContentWidth))
                #expect(approxEqual(bottom.height, layout.cutoutHeight))
                #expect(approxEqual(bottom.maxY, size.height))
            }
        }
    }

    /// Pins the cutout content width to the literal pre-refactor `ScreenShape.path` formula, measured for the
    /// resolved shape type — the one `ScreenShape` actually draws at that size. If a later geometry
    /// change alters what's drawn, this fails with the offending seed — the golden the environment can't eyeball.
    @Test(arguments: TestSeeds.sweep)
    func cutoutContentWidthMatchesReferenceFormula(seed: UInt64) {
        let system = SystemStyles(config: .seedOnly(seed))
        let styles = system.screen
        let insetAmount: CGFloat = 0

        for size in Self.sizes {
            let rect = CGRect(origin: .zero, size: size)
            let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
            let screenShapeType = styles.resolvedScreenShapeType(screenSize: size)
            let cornerRadius = ScreenShape.cornerRadius(rect: rect, insetAmount: insetAmount, screenShapeType: screenShapeType, system: system)
            let cornerOffset = ScreenShape.screenTrapezoidOrHexagonCornerOffset(screenSize: size, insetAmount: insetAmount)

            let replaceableWidth: CGFloat
            switch screenShapeType {
            case .croppedCircle, .croppedSquircle:
                replaceableWidth = insetRect.width - cornerOffset * 2.0
            case .horizontalHexagon:
                let angle = atan((insetRect.height / 2) / cornerOffset)
                let offset = cornerRadius * abs(tan(angle / 2.0))
                replaceableWidth = insetRect.width - (cornerOffset + offset) * 2.0
            case .trapezoid:
                let topSideLength = insetRect.width - cornerOffset * 2
                let topLeadingSpace = (insetRect.width - topSideLength) / 2
                let angle = atan(insetRect.height / topLeadingSpace)
                let topOffset = cornerRadius * abs(tan(angle / 2.0))
                replaceableWidth = insetRect.width - (cornerOffset + topOffset) * 2.0
            default:
                replaceableWidth = insetRect.width - cornerRadius * 2.0
            }

            let cutoutHeight = ScreenShape.cutoutHeight
            let ttw = styles.generalCutoutStyle.totalTransitionWidth(cutoutHeight: cutoutHeight)
            let maxCutoutContentWidth = replaceableWidth - ttw
            let absoluteMax = 600.0 + insetAmount
            let preferred = styles.preferredCutoutContentWidth(screenSize: size) + insetAmount
            let expected = min(preferred, maxCutoutContentWidth, absoluteMax)

            let layout = styles.cutoutLayout(rect: rect, insetAmount: insetAmount, screenShapeType: screenShapeType, system: system)
            #expect(approxEqual(layout.replaceableWidth, replaceableWidth))
            #expect(approxEqual(layout.cutoutContentWidth, expected))
            #expect(approxEqual(layout.totalTransitionWidth, ttw))
        }
    }

    @Test(arguments: [ScreenShapeType.croppedCircle, .croppedSquircle], TestSeeds.representative)
    func croppedShapesReachEveryDisplayEdge(shapeType: ScreenShapeType, seed: UInt64) {
        let system = SystemStyles(config: .seedOnly(seed))
        let styles = ScreenStyles(themeGenerationID: system.generationID, design: system.design,
                                  basicShape: system.basicShape, cornerStyle: system.cornerStyle,
                                  random: SeededRandom(seed: seed), screenShapeType: shapeType)
        let sizes = Self.sizes + [CGSize(width: 800, height: 800), CGSize(width: 320, height: 1_200),
                                  CGSize(width: 2_400, height: 320)]
        for size in sizes {
            for inset: CGFloat in [0, 6, 20] {
                let rect = CGRect(x: 17, y: 23, width: size.width, height: size.height)
                let inner = rect.insetBy(dx: inset, dy: inset)
                let path = ScreenShape(system: system, screenStyles: styles, screenShapeType: shapeType,
                                       connectedEdges: [], insetAmount: inset).path(in: rect)
                // Cutouts may occupy the flat edges' centers. The two curved edges must still reach
                // their exact display limits, and the entire outline must stay within the inset rect.
                let bounds = path.cgPath.boundingBoxOfPath
                #expect(abs(bounds.minX - inner.minX) < 0.01)
                #expect(abs(bounds.maxX - inner.maxX) < 0.01)
                #expect(abs(bounds.minY - inner.minY) < 0.01)
                #expect(abs(bounds.maxY - inner.maxY) < 0.01)
                let edgePoints: [CGPoint] = size.width >= size.height
                    ? [CGPoint(x: inner.minX + 0.01, y: inner.midY), CGPoint(x: inner.maxX - 0.01, y: inner.midY)]
                    : [CGPoint(x: inner.midX, y: inner.minY + 0.01), CGPoint(x: inner.midX, y: inner.maxY - 0.01)]
                // Core Graphics tests the curve directly; SwiftUI hit testing flattens it too coarsely
                // to resolve points this close to the boundary on very elongated screens.
                for point in edgePoints {
                    #expect(path.cgPath.contains(point), "Curved edge misses the display for \(shapeType), \(size), inset \(inset)")
                }
            }
        }
    }

    private func approxEqual(_ a: CGFloat, _ b: CGFloat, tolerance: CGFloat = 0.0001) -> Bool {
        abs(a - b) <= tolerance
    }
}
