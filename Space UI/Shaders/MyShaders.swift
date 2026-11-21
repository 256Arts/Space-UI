import SwiftUI
import RealityKit

enum MyShaders {
    static func occasionalWave(time: any BinaryFloatingPoint, waveLength: any BinaryFloatingPoint, amplitude: any BinaryFloatingPoint, cycleCount: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.occasionalWave(.float(time), .float(waveLength), .float(amplitude), .float(cycleCount))
    }
    
    static func hLines(time: any BinaryFloatingPoint, barHeight: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.hLines(.float(time), .float(barHeight))
    }
    
    static func vLines(time: any BinaryFloatingPoint, barHeight: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.vLines(.float(time), .float(barHeight))
    }
    
    static func crtCurve(radius: any BinaryFloatingPoint, size: CGPoint) -> Shader {
        ShaderLibrary.crtCurve(.float(radius), .float2(size))
    }
    
    static func halftone(blockLength: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.halftone(.float(blockLength))
    }
    
    static func sinebow(size: CGSize, baseColor: Color, time: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.sinebow(.float2(size), .color(baseColor), .float(time))
    }
    
    static func lightspeed(size: CGSize, time: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.lightspeed(.float2(size), .float(time))
    }

    static func chromaticAberration(size: CGSize, strength: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.chromaticAberration(.float2(size), .float(strength))
    }

    static func vignette(size: CGSize, strength: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.vignette(.float2(size), .float(strength))
    }

    static func interference(size: CGSize, time: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.interference(.float2(size), .float(time))
    }

    static func signalNoise(time: any BinaryFloatingPoint, intensity: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.signalNoise(.float(time), .float(intensity))
    }

    static func ledGrille(cellSize: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.ledGrille(.float(cellSize))
    }

    static func bloomGlow(radius: any BinaryFloatingPoint, intensity: any BinaryFloatingPoint) -> Shader {
        ShaderLibrary.bloomGlow(.float(radius), .float(intensity))
    }
}

#if !os(visionOS)
@MainActor
enum MyMaterials {
    static private let library = MTLCreateSystemDefaultDevice()!.makeDefaultLibrary()!
    
    static let surfaceShader = CustomMaterial.SurfaceShader(
        named: "wireframeMaterialSurfaceShader",
        in: library)
    
    static let geometryModifier = CustomMaterial.GeometryModifier(
        named: "wireframeMaterialGeometryModifier",
        in: library)

    static let atmosphereSurfaceShader = CustomMaterial.SurfaceShader(
        named: "atmosphereSurfaceShader",
        in: library)

    static let laserBoltSurfaceShader = CustomMaterial.SurfaceShader(
        named: "laserBoltSurfaceShader",
        in: library)
}
#endif
