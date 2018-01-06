//
//  Recognizer.swift
//  Facial Recog
//
//  Created by Allen X on 1/2/18.
//  Copyright © 2018 allenx. All rights reserved.
//

import Foundation
import Vision
import CoreML

class Recognizer: NSObject {
    
//    var openface: OpenFace!
    
    var allenNetRequest: [VNRequest]!
    
    var openFaceRequest: [VNRequest]!
    
    var faceLandmarksHandler: VNSequenceRequestHandler!
    var faceDetectionHandler: VNSequenceRequestHandler!
    
    var faceLandmarksRequest: VNDetectFaceLandmarksRequest!
    var faceDetectionRequest: VNDetectFaceRectanglesRequest!
    
    private override init() {
        faceLandmarksHandler = VNSequenceRequestHandler()
        faceDetectionHandler = VNSequenceRequestHandler()

        super.init()
    }
    
    public convenience init(landmarksCompletionBlock: VNRequestCompletionHandler?, faceCompletionBlock: VNRequestCompletionHandler?, allenCompletionBlock: VNRequestCompletionHandler?, openFaceCompletionBlock: VNRequestCompletionHandler?) {
        self.init()
        faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: landmarksCompletionBlock)
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: faceCompletionBlock)
        
        // 加载我自己训练的 allenNet 模型（专门用来找我）
        do {
            // Load the Custom Vision model.
            // To add a new model, drag it to the Xcode project browser making sure that the "Target Membership" is checked.
            // Then update the following line with the name of your new model.
            let model = try VNCoreMLModel(for: allen().model)
            let fooRequest = VNCoreMLRequest(model: model, completionHandler: allenCompletionBlock)
            allenNetRequest = [fooRequest]
        } catch {
            fatalError("Can't load allen ML model: \(error)")
        }
        
        // 加载 OpenFace 模型
        do {
            // Load the Custom Vision model.
            // To add a new model, drag it to the Xcode project browser making sure that the "Target Membership" is checked.
            // Then update the following line with the name of your new model.
            let model = try VNCoreMLModel(for: OpenFace().model)
            let fooRequest = VNCoreMLRequest(model: model, completionHandler: openFaceCompletionBlock)
            openFaceRequest = [fooRequest]
        } catch {
            fatalError("Can't load OpenFace ML model: \(error)")
        }
        
    }
    
    // 在一张 CIImage 中检测人脸
    public func recognizeFaceIn(ciImage: CIImage) {
        do {
            try faceDetectionHandler.perform([faceDetectionRequest], on: ciImage)
        } catch {
            log.error(error)/
        }
        
        
    }
    
    // 在一张 CIImage 中检测 Face Landmarks
    public func recognizeFaceLandmarksIn(ciImage: CIImage) {
        do {
            try faceLandmarksHandler.perform([faceLandmarksRequest], on: ciImage)
        } catch {
            log.error(error)/
        }
    }
    
    // 在一帧 CVPixelBuffer 中检测人脸和使用 allenNet
    public func recognizeFaceIn(buffer: CVPixelBuffer) {
        do {
//            log.word("entered")/
            try faceDetectionHandler.perform([faceDetectionRequest], on: buffer)
//            log.word("done")/
        } catch {
            log.error(error)/
        }
        
        do {
            let allenRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer.croppedTo(width: 227, height: 227), options: [:])
            try allenRequestHandler.perform(allenNetRequest)
        } catch {
            log.error(error)/
        }
    }
    
    // 在一帧 CVPixelBuffer 中检测 Face Landmarks 和使用 allenNet
    public func recognizeFaceLandmarksIn(buffer: CVPixelBuffer) {
        do {
            try faceLandmarksHandler.perform([faceLandmarksRequest], on: buffer)
        } catch {
            log.error(error)/
        }
        
        do {
            let allenRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer.croppedTo(width: 227, height: 227), options: [:])
            try allenRequestHandler.perform(allenNetRequest)
        } catch {
            log.error(error)/
        }
    }
    
    // 在一帧 CVPixelBuffer 中使用 OpenFace
    public func recognizeAllenWithOpenFaceIn(buffer: CVPixelBuffer) {
        do {
            let openFaceRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer.croppedTo(width: 96, height: 96), options: [:])
            try openFaceRequestHandler.perform(openFaceRequest)
        } catch {
            log.error(error)/
        }
    }

}
