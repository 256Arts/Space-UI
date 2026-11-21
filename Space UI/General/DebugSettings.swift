// Created by 256 Arts Developer on 2026-08-23.

#if DEBUG
/// Debug-build-only overrides of the generated theme. They live here rather than on the theme types themselves,
/// which are pure seed-derived values — a mutable switch on `SystemStyles` claimed the theme was something a
/// debug build could change out from under a view.
enum DebugSettings {

    /// Draws every label in the system font instead of the theme's sci-fi face, so text is legible while
    /// checking layout. Toggled from the debug menu; `nonisolated(unsafe)` because `SystemStyles.font` is
    /// read from wherever a font is resolved, not only the main actor.
    nonisolated(unsafe) static var fontOverride = false

}
#endif
