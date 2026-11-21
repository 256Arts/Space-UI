//
//  Wireframe.metal
//  Space UI
//
//  Created by 256 Arts Developer on 2024-11-11.
//  Copyright © 2024 256 Arts. All rights reserved.
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>

// Godot Source Credits: https://godotshaders.com/shader/wireframe-shader-godot-4-0/
// https://catlikecoding.com/unity/tutorials/advanced-rendering/flat-and-wireframe-shading/

using namespace metal;

constant half3 albedo = half3(1.0);
constant float wireWidth = 3.0; // ideally between 0.0 and 40.0
constant float wireSmoothness = 0.01; // should be between 0.0 and 0.1

[[visible]]
void wireframeMaterialGeometryModifier(realitykit::geometry_parameters params) {
    float3 barys = float3(0);
    int index = params.geometry().vertex_id() % 3;

    switch (index) {
        case 0:
            barys = float3(1.0, 0.0, 0.0);
            break;
        case 1:
            barys = float3(0.0, 1.0, 0.0);
            break;
        case 2:
            barys = float3(0.0, 0.0, 1.0);
            break;
    }

    params.geometry().set_custom_attribute(float4(barys, 0));
}

[[visible]]
void wireframeMaterialSurfaceShader(realitykit::surface_parameters params) {
    float3 barys = params.geometry().custom_attribute().xyz;
    float3 deltas = fwidth(barys);

    float3 barys_s = smoothstep(deltas * wireWidth - wireSmoothness, deltas * wireWidth + wireSmoothness, barys);
    float wires = min(barys_s.x, min(barys_s.y, barys_s.z));

    float threshold = 0.001;
    if (abs(wires) > threshold) {
        discard_fragment();
    }

    half3 emissive = mix(half3(params.material_constants().base_color_tint()), albedo.rgb, wires);
    params.surface().set_emissive_color(emissive);
}
