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
    
    var faceLandmarksHandler: VNSequenceRequestHandler!
    var faceDetectionHandler: VNSequenceRequestHandler!
    
    var faceLandmarksRequest: VNDetectFaceLandmarksRequest!
    var faceDetectionRequest: VNDetectFaceRectanglesRequest!
    
    private override init() {
        faceLandmarksHandler = VNSequenceRequestHandler()
        faceDetectionHandler = VNSequenceRequestHandler()

        super.init()
    }
    
    public convenience init(landmarksCompletionBlock: VNRequestCompletionHandler?, faceCompletionBlock: VNRequestCompletionHandler?, allenCompletionBlock: VNRequestCompletionHandler?) {
        self.init()
        faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: landmarksCompletionBlock)
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: faceCompletionBlock)
        do {
            // Load the Custom Vision model.
            // To add a new model, drag it to the Xcode project browser making sure that the "Target Membership" is checked.
            // Then update the following line with the name of your new model.
            let model = try VNCoreMLModel(for: allen().model)
            let fooRequest = VNCoreMLRequest(model: model, completionHandler: allenCompletionBlock)
            allenNetRequest = [fooRequest]
        } catch {
            fatalError("Can't load Vision ML model: \(error)")
        }
        
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
        
        do {
            let allenRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer.croppedTo(width: 227, height: 227), options: [:])
            try allenRequestHandler.perform(allenNetRequest)
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
        
        do {
            let allenRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer.croppedTo(width: 227, height: 227), options: [:])
            try allenRequestHandler.perform(allenNetRequest)
        } catch {
            print(error)
        }
    }

}
