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
    
    var faceLandmarksHandler: VNSequenceRequestHandler!
    var faceDetectionHandler: VNSequenceRequestHandler!
    
    var faceLandmarksRequest: VNDetectFaceLandmarksRequest!
    var faceDetectionRequest: VNDetectFaceRectanglesRequest!
    
    private override init() {
        faceLandmarksHandler = VNSequenceRequestHandler()
        faceDetectionHandler = VNSequenceRequestHandler()

        super.init()
    }
    
    public convenience init(landmarksCompletionBlock: VNRequestCompletionHandler?, faceCompletionBlock: VNRequestCompletionHandler?) {
        self.init()
        faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: landmarksCompletionBlock)
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: faceCompletionBlock)
        
    }
    
    public func recognizeFaceIn(ciImage: CIImage) {
        do {
            try faceDetectionHandler.perform([faceDetectionRequest], on: ciImage)
        } catch {
            log.error(error)/
        }
    }
    
    public func recognizeFaceLandmarksIn(ciImage: CIImage) {
        do {
            try faceLandmarksHandler.perform([faceLandmarksRequest], on: ciImage)
        } catch {
            log.error(error)/
        }
    }
    
    public func recognizeFaceIn(buffer: CVPixelBuffer) {
        do {
//            log.word("entered")/
            try faceDetectionHandler.perform([faceDetectionRequest], on: buffer)
//            log.word("done")/
        } catch {
            print(error)
        }
    }
    
    public func recognizeFaceLandmarksIn(buffer: CVPixelBuffer) {
        do {
            try faceLandmarksHandler.perform([faceLandmarksRequest], on: buffer)
        } catch {
            print(error)
        }
    }

}
