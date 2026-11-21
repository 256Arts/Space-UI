#if !os(visionOS)
import SwiftUI
import RealityKit

/// A `.usdz` model drawn as a slowly-orbiting wireframe on a transparent background.
///
/// `Wireframe.metal` discards every fragment that isn't near a triangle edge, so what survives reads as a
/// schematic rather than a solid object — which is what lets this sit *behind* a page's controls as a
/// decorative element instead of competing with them. The surviving fragments are tinted with the material's
/// base color, so `color` is the wire color and should come from `system`, like any other themed element.
///
/// Not visionOS: there a windowed `RealityView` is seen with the user's own eyes and a custom camera has no
/// effect, so the orthographic framing this relies on doesn't apply — the same platform split `Sphere3DView`
/// documents from the other side.
///
/// **Currently unused, and not yet fit to be a page background.** Dropping it behind `PowerManagementPage`
/// was tried on 2026-07-28 and the iOS Simulator drew the `RealityView` as an opaque placeholder box over
/// the whole page — the windowed-`RealityView`-on-non-visionOS problem `Sphere3DView` already records, which
/// is why the planets use the projected 2D `Sphere` there. Before using this anywhere, confirm on real
/// hardware that a windowed `RealityView` composites transparently; if it doesn't, the wireframe look has to
/// be rebuilt the way `Sphere` was, in `Canvas`/SwiftUI rather than RealityKit.
struct WireframeModelView: View {

    /// Name of a `.usdz` in the bundle, e.g. `"starShuttle"`.
    let modelName: String
    /// The wire color. Pull it from `system.colors` — a hardcoded one won't hold across seeds.
    var color: Color = .white

    private static let modelEntityName = "wireframeModel"

    var body: some View {
        RealityView { content in
            let camera = Entity()
            var orth = OrthographicCameraComponent()
            orth.scale = 10
            camera.components.set(orth)
            camera.position.z = -50
            content.entities.append(camera)

            // A decorative background is never worth taking the app down for, so a model that fails to load
            // simply leaves the page with no backdrop — the `try!` here used to crash the whole app.
            guard let model = try? await ModelEntity(named: modelName) else { return }
            model.name = Self.modelEntityName
            model.model?.materials = [Self.wireframeMaterial(color: color)]

            let orbit = OrbitAnimation(
                duration: 10.0,
                axis: [0, 1, 0],
                startTransform: model.transform,
                orientToPath: true,
                bindTarget: .transform,
                repeatMode: .repeat)
            if let animation = try? AnimationResource.generate(with: orbit) {
                model.playAnimation(animation)
            }
            content.entities.append(model)
        } update: { content in
            // Regenerating the seed swaps the palette under a scene that is already built, so the wires have
            // to be re-tinted in place rather than only at load.
            guard let model = content.entities.first(where: { $0.name == Self.modelEntityName }) as? ModelEntity else { return }
            model.model?.materials = [Self.wireframeMaterial(color: color)]
        }
        .realityViewLayoutBehavior(.centered)
        // Decorative, and behind the page's own controls: it must never take a touch off them.
        // (Also dodges the macOS 15.1 bug where hovering causes an `ARView.ray(through:)` crash.)
        .allowsHitTesting(false)
    }

    /// The wireframe material, falling back to the plain unlit one if the shader can't be built — that only
    /// costs the wireframe look, where throwing would cost the page.
    @MainActor
    private static func wireframeMaterial(color: Color) -> any RealityKit.Material {
        let base = UnlitMaterial(color: UIColor(color))
        return (try? CustomMaterial(
            from: base,
            surfaceShader: MyMaterials.surfaceShader,
            geometryModifier: MyMaterials.geometryModifier)) ?? base
    }
}

#Preview {
    WireframeModelView(modelName: "starShuttle")
}
#endif
