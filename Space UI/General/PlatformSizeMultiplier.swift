import CoreGraphics

/// Scales UI dimensions up for the platform's typical viewing distance: larger on TV, slightly larger on Mac.
/// Shared by font sizing (`Font.Name.defaultFontSize`) and line widths (`SystemStyles.mediumLineWidth`).
let platformSizeMultiplier: CGFloat = {
    #if os(tvOS)
    1.5
    #elseif targetEnvironment(macCatalyst)
    1.2
    #else
    1.0
    #endif
}()
