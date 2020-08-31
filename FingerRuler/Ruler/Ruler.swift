//
//  Ruler.swift
//  FingerRuler
//
//  Created by Sumisora on 2020/08/31.
//  Copyright © 2020 MintJian. All rights reserved.
//

import Foundation
import SceneKit

protocol Ruler: SCNNode {
    var rulerModel: SCNNode? { get set }
    var textModel: SCNNode? { get set }
}

protocol RulerData {
    var defaultRulerAccuracy: Int { get }
    var name: String { get set }
}
