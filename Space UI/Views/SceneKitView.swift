//
//  SceneKitView.swift
//  Space UI
//
//  Created by 256 Arts Developer on 2020-03-18.
//  Copyright © 2020 256 Arts Developer. All rights reserved.
//

import SwiftUI
import SceneKit
import SceneKit.ModelIO

// Note: Need to use SceneKit still, because RealityKit is not supported by tvOS 16

struct SceneKitView: UIViewRepresentable {
    
    let scene: SCNScene = {
        let shipModelNames = ["ship1", "ship2", "ship3"]
        let path = Bundle.main.path(forResource: shipModelNames.randomElement()!, ofType: "obj")
        let url = URL(fileURLWithPath: path!)
        let asset = MDLAsset(url: url)
        return SCNScene(mdlAsset: asset)
    }()
    
    func makeUIView(context: Context) -> SCNView {
        return SCNView()
    }
    
    func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = scene
        scnView.backgroundColor = .clear
        
        let ship = scene.rootNode.childNodes[0]
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(Color(color: .primary, opacity: .max))
        material.fillMode = .lines
        ship.geometry?.materials = [material]
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 2.5)))
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        let distance = max(ship.boundingBox.max.x, ship.boundingBox.max.z)
        cameraNode.camera?.orthographicScale = Double(distance) * 1.1
        cameraNode.position = SCNVector3(x: 0, y: distance, z: distance)
        cameraNode.eulerAngles.x = -.pi/4
        scene.rootNode.addChildNode(cameraNode)
    }
    
}

#Preview {
    SceneKitView()
}
