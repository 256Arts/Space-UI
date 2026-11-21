import SwiftUI

@MainActor @Observable
final class SpaceWindowCameraManager {
    
    static let shared = SpaceWindowCameraManager()
    
    var nearbyDeviceDirection: (distance: Float?, angle: Float?) = (nil, nil)
    
    var nearbyDevicePosition: SIMD3<Float>? {
        guard let distance = nearbyDeviceDirection.distance, let angle = nearbyDeviceDirection.angle else { return nil }
        
        return SIMD3<Float>(x: distance * cos(angle), y: distance * sin(angle), z: 0)
    }
    
}
