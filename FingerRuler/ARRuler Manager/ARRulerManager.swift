//
//  ARRulerManager.swift
//  FingerRuler
//
//  Created by Sumisora on 2020/08/30.
//  Copyright © 2020 MintJian. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

enum RulerType:Int {
    case classic = 1
}

class ARRulerManager {
    private var rulersArray: [Ruler] = []
    private var currentRuler: Ruler? = nil
    private var rootNode = SCNNode()
    var current: Ruler? {
        get {
            return currentRuler
        }
    }
    var rulers: [Ruler] {
        return rulersArray
    }
    
    init(to target: SCNNode) {
        rootNode.name = "ARRulerManager"
        target.addChildNode(rootNode)
    }
    
    init(_ type: [RulerType], to target: SCNNode) {
        rootNode.name = "ARRulerManager"
        target.addChildNode(rootNode)
        for eachType in type {
            switch eachType {
            case .classic:
                let classic = ClassicRuler()
                rulersArray.append(classic)
            }
        }
    }
    
    func addRuler(_ type: [RulerType]) {
        for eachType in type {
            switch eachType {
            case .classic:
                let classic = ClassicRuler()
                rulersArray.append(classic)
                currentRuler = classic
                currentRuler!.isHidden = true
                self.rootNode.addChildNode(classic)
            }
        }
    }
    
    func update(classicRuler: ClassicRuler, width: CGFloat, position: SCNVector3, transform: SCNMatrix4) {
        classicRuler.isHidden = false
        classicRuler.updateWidth(to: width)
        classicRuler.worldPosition = position
        classicRuler.updateText(with: "\(width * 100)")
        // MARK: - There is a bug.
//        classicRuler.transform = transform
    }
}


