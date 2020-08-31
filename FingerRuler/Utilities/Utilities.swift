//
//  Utilities.swift
//  FingerTipsRuler
//
//  Created by Sumisora on 2020/08/29.
//

import Foundation
import UIKit
import SceneKit

let isDeBugging = true

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
}

extension CGFloat {
    func angleToRadian() -> CGFloat {
        return self / 180.0 * CGFloat.pi
    }
    func round(to places: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return (self * divisor).rounded() / divisor
    }
}

func convertRadianFrom(degree: Double) -> Double {
    return degree / 180.0 * Double.pi
}

let screenWidth = UIScreen.main.bounds.size.width
let screentHeight = UIScreen.main.bounds.size.height
// 底部安全距离
let bottomSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0.0
//顶部的安全距离
let topSafeAreaHeight = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0.0
//状态栏高度
//let statusBarHeight = UIApplication.shared.statusBarFrame.height;
//导航栏高度
let navigationBarHeight = CGFloat(44 + topSafeAreaHeight)

func midPoint(_ x: SCNVector3, _ y: SCNVector3) -> SCNVector3 {
    let midX = (x.x + y.x) / 2
    let midY = (x.y + y.y) / 2
    let midZ = (x.z + y.z) / 2
    return SCNVector3(midX, midY, midZ)
}

func setupTransform(from startPoint: SCNVector3,
                                      to endPoint: SCNVector3) -> SCNMatrix4? {
    let w = SCNVector3(x: endPoint.x-startPoint.x,
                       y: endPoint.y-startPoint.y,
                       z: endPoint.z-startPoint.z)
    let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
    
    var transform = SCNMatrix4()
    
    if l == 0.0 {
        return nil
    }
    
    //original vector of cylinder above 0,0,0
    let ov = SCNVector3(0, l/2.0,0)
    //target vector, in new coordination
    let nv = SCNVector3((endPoint.x - startPoint.x)/2.0, (endPoint.y - startPoint.y)/2.0,
                        (endPoint.z-startPoint.z)/2.0)
    
    // axis between two vector
    let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)
    
    //normalized axis vector
    let av_normalized = normalizeVector(av)
    let q0 = Float(0.0) //cos(angel/2), angle is always 180 or M_PI
    let q1 = Float(av_normalized.x) // x' * sin(angle/2)
    let q2 = Float(av_normalized.y) // y' * sin(angle/2)
    let q3 = Float(av_normalized.z) // z' * sin(angle/2)
    
    let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
    let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
    let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
    let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
    let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
    let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
    let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
    let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
    let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
    
    transform.m11 = r_m11
    transform.m12 = r_m12
    transform.m13 = r_m13
    transform.m14 = 0.0
    
    transform.m21 = r_m21
    transform.m22 = r_m22
    transform.m23 = r_m23
    transform.m24 = 0.0
    
    transform.m31 = r_m31
    transform.m32 = r_m32
    transform.m33 = r_m33
    transform.m34 = 0.0
    
    transform.m41 = (startPoint.x + endPoint.x) / 2.0
    transform.m42 = (startPoint.y + endPoint.y) / 2.0
    transform.m43 = (startPoint.z + endPoint.z) / 2.0
    transform.m44 = 1.0
    return transform
}


func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
    let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)
    if length == 0 {
        return SCNVector3(0.0, 0.0, 0.0)
    }
    
    return SCNVector3( iv.x / length, iv.y / length, iv.z / length)
    
}
