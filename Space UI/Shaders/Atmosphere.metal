//
//  Atmosphere.metal
//  Space UI
//
//  Created by 256 Arts Developer on 2026-07-06.
//  Copyright © 2026 256 Arts. All rights reserved.
//

#include <metal_stdlib>
// RealityKit's CustomMaterial shader headers don't exist on visionOS (see the #if !os(visionOS) fallbacks
// in the Swift call sites), so compile this shader out where they're absent.
#if __has_include(<RealityKit/RealityKit.h>)
#include <RealityKit/RealityKit.h>

using namespace metal;

constant float planetRadius = 0.1; // Planet models' bounds are 0.2 cubed
constant float atmosphereRadius = 0.12; // Must match the sphere radius in addAtmosphere(to:)

/// An atmosphere glow that peaks at the planet's limb, fades smoothly outward to the top of the atmosphere, and bleeds a little inward over the planet's face. Rendered on a sphere larger than the planet.
[[visible]]
void atmosphereSurfaceShader(realitykit::surface_parameters params) {
    // Work in view space (where the camera is at the origin), and measure how close each fragment's view ray passes to the planet's center
    float4x4 modelToView = params.uniforms().model_to_view();
    float3 planetCenter = (modelToView * float4(0, 0, 0, 1)).xyz;
    float3 rayDirection = normalize((modelToView * float4(params.geometry().model_position(), 1)).xyz);
    float scale = length((modelToView * float4(1, 0, 0, 0)).xyz);
    float rayPlanetDistance = length(cross(planetCenter, rayDirection)) / scale; // In model-space units

    float glow;
    if (rayPlanetDistance > planetRadius) {
        // Above the limb: fade outward with altitude
        float altitude = (rayPlanetDistance - planetRadius) / (atmosphereRadius - planetRadius);
        glow = pow(saturate(1.0 - altitude), 3.0);
    } else {
        // Over the planet's face: a thin haze that fades quickly inward from the limb
        float depth = (planetRadius - rayPlanetDistance) / planetRadius;
        glow = exp(-20.0 * depth);
    }
    params.surface().set_emissive_color(half3(params.material_constants().base_color_tint()) * half(glow) * 0.8h);
    params.surface().set_opacity(half(glow) * 0.8h);
}
#endif
