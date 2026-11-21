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
    
    // Only 1 in `cycleCount` segments of the cos wave will be used
    if (cycle == 0) {
        position.x += (cos(cosParams) - 1) * amplitude / 2;
    } else if (cycle == cycleCount) {
        // Wave segments will alternate facing left/right
        position.x -= (cos(cosParams) - 1) * amplitude / 2;
    }
    
    return position;
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

/// A shader that generates multiple twisting and turning lines that cycle through colors
[[ stitchable ]] half4 sinebow(float2 position, half4 color, float2 size, half4 baseColor, float time) {
    // Calculate our aspect ratio.
    half aspectRatio = size.x / size.y;

    // Calculate our coordinate in UV space, -1 to 1.
    half2 uv = half2(position / size.x) * 2.0h - 1.0h;

    // Make sure we can create the effect roughly equally no
    // matter what aspect ratio we're in.
    uv.x /= aspectRatio;

    // Calculate the overall wave movement.
    // Square that movement, and multiply by a large number
    // to make the peaks and troughs be nice and big.
    half wave = pow(sin(uv.x + time), 2) * 50.0h;

    // Assume a clear color by default.
    half4 resultColor = half4(0.0h);

    // Create 10 lines in total.
    for (half i = 0.0h; i < 3.0h; i += 0.3h) {
        // This calculates a second sine wave that's unique
        // to each line, so we get waves inside waves.
        half y = sin(uv.x * sin(time) + i * 0.666 + time);

        // This offsets each line by that second wave amount,
        // so the waves move non-uniformly.
        uv.y += 0.05h * y;

        // RGB offsets to add rainbow effect.
        // The * 0.8h part ensures the values
        // are between -0.8 and 0.8 rather than -1 and 1.
        // (Otherwise there are some harsh color transisions. Maybe P3 related.)
        half4 rgbOffsets = half4(
            sin(i + sin(time * 0.2h)),
            sin(i + 2.0h + sin(time * 0.3h) * 2.0h),
            sin(i + 4.0h + sin(time * 0.7h) * 4.0h),
            0.0h
        ) * 0.8h;
        
        // The base brightness of this pixel is 1%, but we
        // need to factor in the position after our wave
        // calculation is taken into account. The abs()
        // call ensures negative numbers become positive,
        // so we care about the absolute distance to the
        // nearest line, rather than ignoring values that
        // are negative.
        half alpha = pow(abs(1.0h / (100.0h * uv.y + wave)), 3);

        // Add that to the current wave color, ensuring that
        // pixels receive some brightness from all lines.
        resultColor += clamp(baseColor + rgbOffsets, half4(0.0h), half4(1.0h)) * alpha;
    }

    // Send back the finished color, taking into account the
    // current alpha value.
    return resultColor;
}


/// Bloom bright-pass: keeps only the light above the threshold, preserving color (unlike `MPSImageThresholdToZero`, which outputs grayscale)
kernel void bloomBrightPass(texture2d<half, access::read> source [[texture(0)]],
                            texture2d<half, access::write> destination [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]])
{
    half4 color = source.read(gid);
    const half threshold = 0.5h;
    half3 bright = max(color.rgb - threshold, 0.0h) / (1.0h - threshold);
    destination.write(half4(bright, color.a), gid);
}

// Change the anti-aliasing to 1 if it's too slow
constant int AA = 2;
constant float PI = 3.14159265;
constant float ATAN5 = 1.37340076695;

float2 cart2polar(float2 cart) {
    return float2(atan2(cart.y, cart.x), length(cart));
}

// From https://www.shadertoy.com/view/4sc3z2
// and https://www.shadertoy.com/view/XsX3zB
constant float3 MOD3 = float3(.1031,.11369,.13787);
float3 hash33(float3 p3)
{
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
float simplexNoise(float3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    float3 i = floor(p + (p.x + p.y + p.z) * K1);
    float3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    float3 e = step(float3(0.0), d0 - d0.yzx);
    float3 i1 = e * (1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    float3 d1 = d0 - (i1 - 1.0 * K2);
    float3 d2 = d0 - (i2 - 2.0 * K2);
    float3 d3 = d0 - (1.0 - 3.0 * K2);
    
    float4 h = max(0.6 - float4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    float4 n = h * h * h * h * float4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    
    return dot(float4(31.316), n);
}


float linearstep(float low, float high, float val)
{
    return clamp((val-low) / (high-low), 0.0, 1.0);
}
float jumpstep(float low, float high, float val)
{
    if(2.0 * val < high + low) {
        return clamp(atan(10.0 * (val-low) / (high-low) - 5.0) / (2.0 * ATAN5) + 0.5, 0.0, 1.0);
    }
    else {
        return (10.0 * (val-low) / (high-low) - 5.0) / (2.0 * ATAN5) + 0.5;
    }
}

half3 pixelVal(float2 coord, float2 size, float iTime)
{
    // Pixel to point (the center of the screen is (0,0)
    float2 resolution = size * float(AA);
    float2 uv = (2.0*coord - resolution.xy) / resolution.x;
    float2 ad = cart2polar(uv);
    
    // Loop forever
    float time = mod(iTime, 8.0);
    
    half3 bg = half3(0,0,0.05);
    half3 col = bg;
 
    // Initial step, just roaming in space
    if(time < 3.5) {
        float r = ad.y / (1.0+0.042*time);
        float noiseVal = simplexNoise(float3(60.0*ad.x,50.0*r, 0.0));
        float whiteIntensity = smoothstep(0.7, 1.0, noiseVal)
                               * (1.0 - smoothstep(2.8,3.5,time));
        col = mix(col, half3(1,1,1), whiteIntensity);
    }
    // The effect starts
    if(time >= 2.8 && time < 4.5) {
        float blueTime = 1.0 - 1.0*smoothstep(2.8, 5.0, time);
        float whiteTime = 1.0 - 0.6*smoothstep(3.0, 5.0, time);
        float r = ad.y / (1.0+0.15*linearstep(0.0, 3.5, time))
                  *(40.0 / (3.0 + 20.0*jumpstep(2.8, 6.0, 0.5*pow(time,1.5))));
        float noiseVal = simplexNoise(float3(40.0*ad.x,r, 0.0));
        col = mix(col, half3(0.5,0.7,1), smoothstep(2.8, 3.5, time)
                                        *smoothstep(0.4*blueTime, blueTime, noiseVal));
        col = mix(col, half3(1,1,1), smoothstep(2.8, 3.5, time)
                                    *smoothstep(0.7 * whiteTime, whiteTime, noiseVal));
        
        // Dark at the center
        col = mix(col, bg, smoothstep(2.8, 3.4, time) * (1.0 - ad.y));
    }
    // Fade to white
    if(time > 4.2 && time < 4.5) {
        col = mix(col, half3(0.9,0.95,1.0), smoothstep(4.2,4.5, time));
    }
    // Fade to black with stars (decelerating)
    else if(time > 4.5) {
        float r = ad.y / (1.0 + 2.0/PI*atan(-0.042*(8.0-time))/cos((8.0-time)/2.2));
        float noiseVal = simplexNoise(float3(60.0*ad.x,50.0*r, 0.0));
        float whiteIntensity = smoothstep(0.7, 1.0, noiseVal);
        col = mix(col, half3(1,1,1), whiteIntensity);
        col = mix(col, half3(0.9,0.95,1.0), 1.0-smoothstep(4.5,5.0, time));
    }

    return col;
}

[[ stitchable ]] half4 lightspeed(float2 position, half4 color, float2 size, float time)
{
    half3 avgcol = half3(0.0);
    
    for (int i = 0; i < AA; i++) {
        for (int j = 0; j < AA; j++) {
            avgcol += pixelVal(float(AA)*position + float2(i, j), size, time);
        }
    }
        
    avgcol /= half(AA*AA);


    // Output to screen
    return half4(avgcol, 1.0);
}

// MARK: - Screen FX

/// Static chromatic aberration: shifts red/blue samples radially, strongest at the edges.
/// No time input, so it never keeps the animation clock running.
[[ stitchable ]] half4 chromaticAberration(float2 position, SwiftUI::Layer layer, float2 size, float strength) {
    float2 offset = position / size - 0.5;
    float edge = length(offset) * 1.414; // 0 center -> ~1 corner
    // Quadratic falloff: untouched center, `strength` points of shift at the corners
    float2 shift = offset * edge * 2.0 * strength;
    half4 color = layer.sample(position);
    color.r = layer.sample(position - shift).r;
    color.b = layer.sample(position + shift).b;
    // Brighten toward the edges, where the fringing lives, so the split reads more clearly
    color.rgb *= half(1.0 + edge * edge * 0.35);
    return color;
}

/// Static corner darkening, suggesting the bulge of a tube screen
[[ stitchable ]] half4 vignette(float2 position, half4 currentColor, float2 size, float strength) {
    float2 offset = position / size - 0.5;
    float edge = length(offset) * 1.414; // 0 center -> ~1 corner
    half darken = half(1.0 - strength * edge * edge * edge);
    return half4(currentColor.rgb * max(darken, 0.0h), currentColor.a);
}

/// Signal-interference band that sweeps down the screen, brightening a soft horizontal stripe like
/// bad reception. A colour-only ambient effect (an alternative to the geometry-warping `occasionalWave`).
[[ stitchable ]] half4 interference(float2 position, half4 currentColor, float2 size, float time) {
    float sweep = fract(time * 0.14) * size.y;              // band center travels top->bottom over ~7s
    float dist = position.y - sweep;
    float band = exp(-(dist * dist) / (2.0 * 30.0 * 30.0)); // ~30px soft band
    float ripple = 0.5 + 0.5 * sin(position.y * 0.5 + time * 30.0); // scanline flicker within the band
    half boost = half(band * (0.2 + 0.3 * ripple));
    return half4(currentColor.rgb * (1.0h + boost), currentColor.a);
}

/// Per-pixel static, like a weak transmission. Intensity is driven from ship state.
[[ stitchable ]] half4 signalNoise(float2 position, half4 currentColor, float time, float intensity) {
    // mod() keeps hash inputs small so precision holds on screens left running for days
    float noise = hash33(float3(position, mod(time, 120.0) * 60.0)).x; // -1...1
    return half4(currentColor.rgb * half(1.0 + noise * intensity), currentColor.a);
}

/// Static LED-panel grille: darkens thin gaps between square cells
[[ stitchable ]] half4 ledGrille(float2 position, half4 currentColor, float cellSize) {
    float2 cell = fract(position / cellSize);
    float2 fromCenter = abs(cell - 0.5) * 2.0; // 0 center -> 1 cell edge
    half gap = half(smoothstep(0.65, 1.0, max(fromCenter.x, fromCenter.y)));
    return half4(currentColor.rgb * (1.0h - 0.4h * gap), currentColor.a);
}

/// Emergency bloom: 16-tap two-ring blur of a bright pass, added back over the source.
/// Deliberately cheap — and only enabled while alarm colors strobe.
[[ stitchable ]] half4 bloomGlow(float2 position, SwiftUI::Layer layer, float radius, float intensity) {
    half4 color = layer.sample(position);
    const half threshold = 0.55h;
    half3 glow = half3(0.0h);
    for (int ring = 1; ring <= 2; ring++) {
        float r = radius * float(ring) * 0.5;
        float phase = (ring == 2) ? 0.3927 : 0.0; // stagger outer taps between inner ones
        for (int i = 0; i < 8; i++) {
            float angle = phase + float(i) * (PI / 4.0);
            half3 s = layer.sample(position + float2(cos(angle), sin(angle)) * r).rgb;
            glow += max(s - threshold, half3(0.0h)) / (1.0h - threshold);
        }
    }
    return half4(color.rgb + glow * (half(intensity) / 16.0h), color.a);
}
