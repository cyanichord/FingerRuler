//
//  FingerProcessor.swift
//  FingerRuler
//
//  Created by Sumisora on 2020/08/31.
//  Copyright © 2020 MintJian. All rights reserved.
//

import Foundation
import AVFoundation
import Vision

private var handPoseRequest = VNDetectHumanHandPoseRequest()

struct Finger2DPosition {
    private var thumbTip2D: CGPoint?
    private var indexTip2D: CGPoint?
    var thumbTip: CGPoint? { get { return thumbTip2D} }
    var indexTip: CGPoint? { get { return indexTip2D} }
    
    init(_ thumbTip2D: CGPoint?, _ indexTip2D: CGPoint?) {
        self.thumbTip2D = thumbTip2D
        self.indexTip2D = indexTip2D
    }
}

func getTip2DPosition(in image: CVPixelBuffer) -> Finger2DPosition? {
    var thumbTip: CGPoint?
    var indexTip: CGPoint?
    
    let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
    do {
        try handler.perform([handPoseRequest])
        guard let observation = handPoseRequest.results?.first else {
            return nil
        }
        let thumbPoints = try observation.recognizedPoints(.thumb)
        let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
        guard let thumbTipPoint = thumbPoints[.thumbTip], let indexTipPoint = indexFingerPoints[.indexTip] else {
            return nil
        }
        guard thumbTipPoint.confidence > 0.8 && indexTipPoint.confidence > 0.8 else {
            return nil
        }
        
        thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
        indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
        
    } catch {
        
    }
    let finger2DPosition = Finger2DPosition(thumbTip, indexTip)
    return finger2DPosition
}
