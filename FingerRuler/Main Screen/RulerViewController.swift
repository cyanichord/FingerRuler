//
//  ClassicRuler+Helper.swift
//  FingerTipsRuler
//
//  Created by Sumisora on 2020/08/29.
//

import Foundation
import UIKit
import SceneKit
import ARKit
import os

class ClassicRulerViewController: UIViewController {
    
    private var sceneView: ARSCNView!
    private var isMeasuring: Bool = false
    private var rulerManager: ARRulerManager!
    private var screenBoundsFrame: CGRect!
    private var screenBoundsFrameSemaphore = DispatchSemaphore(value: 1)
    private var lastObservationTimestamp = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupARConfiguration()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupRulerManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func setupView() {
        let view = ARSCNView(frame: CGRect(x: 0, y: topSafeAreaHeight, width: screenWidth, height: screentHeight - topSafeAreaHeight - bottomSafeAreaHeight))
        let scene = SCNScene()
        self.view = view
        view.scene = scene
        sceneView = view
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        screenBoundsFrame = sceneView.bounds
    }
    
    func setupARConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
    }
    
    func setupRulerManager() {
        rulerManager = ARRulerManager(to: sceneView.scene.rootNode)
        rulerManager.addRuler([.classic])
        isMeasuring = true
    }
}

extension ClassicRulerViewController: ARSCNViewDelegate {
    // MARK: - ARSCNViewDelegate
    
    func getFingerTip2DPosition() -> Finger2DPosition? {
        guard let image = sceneView.session.currentFrame?.capturedImage else {
            os_log("Can not get current frame of ARCamera.")
            return nil
        }
        let tipsPosition = getTip2DPosition(in: image)
        DispatchQueue.main.sync { [self] in
            screenBoundsFrameSemaphore.wait()
            screenBoundsFrame = sceneView.bounds
            screenBoundsFrameSemaphore.signal()
        }
        screenBoundsFrameSemaphore.wait()
        let currentFrameBounds = screenBoundsFrame!
        screenBoundsFrameSemaphore.signal()
        
        
        let thumbPosition = tipsPosition?.thumbTip
        let indexPosition = tipsPosition?.indexTip
        var thumbPositionConverted: CGPoint? = nil
        var indexPositionConverted: CGPoint? = nil
        
        
        if thumbPosition != nil {
            let x = currentFrameBounds.width * thumbPosition!.x
            let y = currentFrameBounds.height * thumbPosition!.y
            thumbPositionConverted = CGPoint(x: x, y: y)
        }
        if indexPosition != nil {
            let x = currentFrameBounds.width * indexPosition!.x
            let y = currentFrameBounds.height * indexPosition!.y
            indexPositionConverted = CGPoint(x: x, y: y)
        }
        
        let tipsPositionConverted = Finger2DPosition(thumbPositionConverted, indexPositionConverted)
        return tipsPositionConverted
    }
    
    func transferTo3DPosition(from point: CGPoint) -> SCNVector3? {
        var position = SCNVector3()
        guard let query = sceneView.raycastQuery(from: point, allowing: .existingPlaneInfinite, alignment: .any) else {
            os_log("There is no plane tracked.")
            return nil
        }
        sceneView.session.trackedRaycast(query, updateHandler:{ results in
            guard let result = results.first else {
                os_log("There is no plane tracked.")
                return
            }
            position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            
        })
        
        return position
    }
    
    func updateCurrentClassicRuler() {
        guard let current = rulerManager.current as? ClassicRuler else {
            os_log("Current ruler is not classic ruler.")
            return
        }
        guard let finger2DPosition = self.getFingerTip2DPosition(),
              finger2DPosition.indexTip != nil,
              finger2DPosition.thumbTip != nil else {
            return
        }
        
        
        guard let thumbPosition = self.transferTo3DPosition(from: finger2DPosition.thumbTip!),
              let indexPosition = self.transferTo3DPosition(from: finger2DPosition.indexTip!) else {
            os_log("Can not update current classic ruler.")
            return
        }
        
        let twoFingerDistance = CGFloat(
            sqrt((thumbPosition.x - indexPosition.x) * (thumbPosition.x - indexPosition.x) +
                (thumbPosition.y - indexPosition.y) * (thumbPosition.y - indexPosition.y) +
                (thumbPosition.z - indexPosition.z) * (thumbPosition.z - indexPosition.z))
        )
        
        if twoFingerDistance == 0{
            return
        }
        
        // MARK: - There is a Bug.
        if twoFingerDistance >= 0.20{
            return
        }
        
        print(twoFingerDistance )
        let midPosition = midPoint(thumbPosition, indexPosition)
        let transform = setupTransform(from: thumbPosition, to: indexPosition) ?? current.rulerModel!.transform
        
        rulerManager.update(classicRuler: current, width: twoFingerDistance, position: midPosition, transform: transform)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if isMeasuring &&
            Date().timeIntervalSince(lastObservationTimestamp) > 0.1 {
            lastObservationTimestamp = Date()
            DispatchQueue.global().async { [self] in
                let current = self.rulerManager.current
                guard current != nil else { return }
                
                if ((current as? ClassicRuler) != nil) {
                    self.updateCurrentClassicRuler()
                }
            }
        }
    }
    
    func createPlane(with planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNNode()
        let geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        geometry.firstMaterial!.diffuse.contents = UIColor.white
        plane.geometry = geometry
        plane.opacity = 0.4
        plane.position = SCNVector3(planeAnchor.center.x, 0,planeAnchor.center.z)
        plane.name = "detectedPlane"
        plane.eulerAngles.x -= Float.pi / 2
        
        return plane
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//        let newPlane = createPlane(with: planeAnchor)
//        let existPlane = node.childNode(withName: "detectedPlane", recursively: false)
//        
//        if existPlane == nil {
//            node.addChildNode(newPlane)
//        } else {
//            let oldVolume = (existPlane!.geometry as! SCNPlane).width * (existPlane!.geometry as! SCNPlane).height
//            let newVolume = (newPlane.geometry as! SCNPlane).width * (newPlane.geometry as! SCNPlane).height
//            
//            if oldVolume < newVolume {
//                existPlane!.removeFromParentNode()
//                node.addChildNode(newPlane)
//            }
//        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
