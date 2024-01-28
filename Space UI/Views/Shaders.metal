//
//  Shaders.metal
//  Space UI
//
//  Created by 256 Arts Developer on 2023-09-03.
//  Copyright © 2023 256 Arts Developer. All rights reserved.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Modulo
float mod(float x, float y) {
    return x - y * floor(x / y);
}

[[ stitchable ]] float2 occasionalWave(float2 position, float time, float waveLength, float amplitude, float cycleCount) {
    float cosParams = time + (position.y / waveLength);
    float waveNumber = cosParams / (M_PI_F * 2);
    float cycle = floor(mod(waveNumber, cycleCount * 2));
    float positionX;
    
    // Only 1 in <cycleCount> segments of the cos wave will be used
    if (cycle == 0) {
        positionX = position.x + (cos(cosParams) - 1) * amplitude / 2;
    } else if (cycle == cycleCount) {
        // Wave segments will alternate facing left/right
        positionX = position.x - (cos(cosParams) - 1) * amplitude / 2;
    } else {
        // Most of the time, no wave is applied
        positionX = position.x;
    }
    
    return float2(positionX, position.y);
}

[[ stitchable ]] half4 hLines(float2 position, half4 currentColor, float time, float barHeight) {
    float lineNumber = mod(time + (position.y / barHeight), 2);
    return lineNumber < 1 ? currentColor : currentColor * 0.5;
}

[[ stitchable ]] half4 vLines(float2 position, half4 currentColor, float time, float barWidth) {
    float lineNumber = mod(time + (position.x / barWidth), 2);
    return lineNumber < 1 ? currentColor : currentColor * 0.5;
}

// using normal vectors of a sphere
[[ stitchable ]] float2 crtCurve(float2 position, float radius, float2 size) {
//    float radius = 2.0;
    position = (position / size) - 0.5; // position is now -1 to 1
    position = radius*position / sqrt(radius*radius - dot(position, position));
    position = (0.5 + position) * size; // back to normal coords
    return position;
}

/// Returns the alpha of a pixel being drawn for a circle
bool circleAlpha(float2 position, float2 center, float radius) {
    float dist = length(center - position);
    return dist <= radius;
}

[[ stitchable ]] half4 halftone(float2 position, SwiftUI::Layer layer, float blockLength) {
    float2 topLeft = float2(position.x - fmod(position.x, blockLength), position.y - fmod(position.y, blockLength));
    float2 center = topLeft + (blockLength / 2);
    half4 sampleColor = layer.sample(center);
    half radius = (sampleColor.r + sampleColor.g + sampleColor.b + sampleColor.a) * blockLength / 8;
    if (circleAlpha(position, center, radius)) {
        return half4(sampleColor.rgb, 1.0);
    } else {
        return half4(0, 0, 0, 0);
    }
}
