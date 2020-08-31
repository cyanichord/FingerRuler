//
//  ClassicRuler.swift
//  FingerTipsRuler
//
//  Created by Sumisora on 2020/08/29.
//

import Foundation
import UIKit
import SceneKit
import os

class ClassicRulerData: RulerData {
    var defaultRulerAccuracy: Int = 3
    var name: String = ""
    
    let defaultWidth: CGFloat = 0.1
    let defaultHeight: CGFloat = 0.002
    let defaultLength: CGFloat = 0.02
    let defaultCRadius: CGFloat = 0.002
    
    private var currentWidth: CGFloat = 0 {
        didSet {
            if currentWidth < 0 {
                currentWidth = 0
            }
        }
    }

    var height: CGFloat {
        get {
            return defaultHeight
        }
    }
    var width: CGFloat {
        get {
            return currentWidth
        }
    }
    
    init() {
    }
    
    init(width: CGFloat) {
        currentWidth = width
    }
    
    func update(width: CGFloat) {
        currentWidth = width
    }
}

class ClassicRuler: SCNNode, Ruler {
    var rulerModel: SCNNode? = nil
    var textModel: SCNNode? = nil
    private var data = ClassicRulerData()
    var width: CGFloat {
        get {
            return data.width
        }
    }
    
    override init() {
        super.init()
        createRuler()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createRuler() {
        let model = SCNNode()
        let boxGeometry = SCNBox(width: data.defaultWidth, height: data.defaultHeight, length: data.defaultLength, chamferRadius: data.defaultCRadius)
        boxGeometry.firstMaterial?.diffuse.contents = UIColor.black
        model.geometry = boxGeometry
        model.position = SCNVector3(0, 0, 0)
        
        guard let scene = SCNScene(named: "art.scnassets/text.scn"),
            let textTemplate = scene.rootNode.childNode(withName: "textNode", recursively: true)
            else {
                os_log("Can not create ruler model. Need text.scn")
                return
        }
        
        let text = textTemplate.clone()
        rulerModel = model
        textModel = text
        
        addChildNode(model)
        addChildNode(text)
    }
    
    func updateWidth(to newValue: CGFloat) {
        guard rulerModel != nil,
              let geo = rulerModel!.geometry as? SCNBox else {
            os_log("Can not update ruler width. Model is nil.")
            return
        }
        geo.width = newValue
        data.update(width: newValue)
    }
    
    func updateText(with text: String) {
        guard textModel != nil,
              let geo = textModel!.geometry as? SCNText else {
            os_log("Can not update text width. Model is nil.")
            return
        }
        geo.string = text
    }
}
