//
//  Laser.metal
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

// Must match the box mesh in `makeLaserBolt()`: box size is (2*glowRadius, 2*glowRadius, 2*halfLength).
constant float boltHalfLength = 30.0;
constant float boltGlowRadius = 5.0;
constant float boltCoreRadius = 1.3;

/// A volumetric laser bolt: rather than shading the box surface (which foreshortens to a smear when the bolt
/// points at the camera), we measure how close each fragment's view ray passes to the bolt's central axis — the
/// segment down the middle of the box — and build the glow from that. The result reads as a white-hot core in a
/// smooth green halo from every angle, and the bright emissive feeds the scene bloom for extra glow.
[[visible]]
void laserBoltSurfaceShader(realitykit::surface_parameters params) {
    // Work in view space, where the camera sits at the origin (same trick as the atmosphere shader).
    float4x4 modelToView = params.uniforms().model_to_view();
    float3 axisA = (modelToView * float4(0, 0, -boltHalfLength, 1)).xyz;
    float3 axisB = (modelToView * float4(0, 0,  boltHalfLength, 1)).xyz;
    float3 fragView = (modelToView * float4(params.geometry().model_position(), 1)).xyz;
    float3 rayDirection = normalize(fragView); // View ray from the camera through this fragment.

    // Closest distance between the view ray (origin, rayDirection) and the bolt axis line (through axisA).
    float3 axisDirection = normalize(axisB - axisA);
    float3 perp = cross(rayDirection, axisDirection);
    float perpLength = length(perp);
    float distance;
    if (perpLength < 1e-4) {
        distance = length(cross(axisA, rayDirection)); // Ray parallel to axis: point-to-ray distance.
    } else {
        distance = abs(dot(axisA, perp)) / perpLength;
    }
    float scale = length((modelToView * float4(1, 0, 0, 0)).xyz);
    distance /= scale; // Back into model-space units.

    float core = saturate(1.0 - distance / boltCoreRadius); // White-hot center.
    float halo = pow(saturate(1.0 - distance / boltGlowRadius), 2.0); // Smooth green falloff.
    float intensity = max(core, halo);

    half3 green = half3(0.15, 1.0, 0.3);
    half3 white = half3(1.0, 1.0, 1.0);
    half3 color = mix(green, white, half(core * core));

    params.surface().set_base_color(half3(0.0));
    params.surface().set_emissive_color(color * half(intensity) * 6.0h);
    params.surface().set_opacity(half(saturate(intensity)));
}
#endif
