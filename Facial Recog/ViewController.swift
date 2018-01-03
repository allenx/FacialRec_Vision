//
//  ViewController.swift
//  Facial Recog
//
//  Created by Allen X on 1/2/18.
//  Copyright © 2018 allenx. All rights reserved.
//

import UIKit
import Vision
import CoreML
import CoreMedia
import AVFoundation

struct MetaData {
    static let videoWidth: CGFloat = 360
    static let videoHeight: CGFloat = 480
}

class ViewController: UIViewController {
    
    var photographer: Photographer!
    
    var currentBuffer: CVPixelBuffer?
    var currentRectangles: [CAShapeLayer] = []
    var currentLandmarks: [CAShapeLayer] = []
    
    var videoPreviewView: UIView!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    let commandGroup = DispatchGroup()
    
    
    var recognizer: Recognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        videoPreviewView = UIView(frame: view.frame)
        view.addSubview(videoPreviewView)
        
        recognizer = Recognizer(
            landmarksCompletionBlock: self.didFinishLandmarksRecog,
            faceCompletionBlock: self.didFinishFaceRecog
        )
        
        
        
        photographer = Photographer()
        photographer.delegate = self
        
        commandGroup.enter()
        photographer.setup(sessionPreset: .medium) {
            succeeded in
            guard succeeded else {
                return
            }
            if let previewLayer = self.photographer.previewLayer {
                self.videoPreviewLayer = previewLayer
                self.videoPreviewView.layer.addSublayer(previewLayer)
                self.videoPreviewLayer.frame = self.videoPreviewView.bounds
            }
            self.commandGroup.leave()
        }
        
        commandGroup.notify(queue: .main) {
            self.photographer.start()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// 完成「脸部矩形检测」和「五官检测」的函数
extension ViewController {
    fileprivate func didFinishFaceRecog(request: VNRequest, error: Error?) {
        
        if let results = request.results as? [VNFaceObservation] {
            //            log.word("检测到 \(results.count) 张人脸")/
            DispatchQueue.main.async {
                self.drawRectangles(faceObservations: results)
            }
            
        } else {
            log.error(error!)/
        }
    }
    
    fileprivate func didFinishLandmarksRecog(request: VNRequest, error: Error?) {
        //        log.word("done")/
        if let results = request.results as? [VNFaceObservation] {
            //            log.word("检测到 \(results.count) 张人脸")/
            DispatchQueue.main.async {
                self.drawLandmarks(faceObservations: results)
            }
            
        } else {
            log.error(error!)/
        }
    }
}

// 在 View 上，通过检测到的结果绘制矩形框和五官的函数
extension ViewController {
    fileprivate func drawRectangles(faceObservations: [VNFaceObservation]) {
        currentRectangles = currentRectangles.flatMap {
            rectangle in
            rectangle.removeFromSuperlayer()
            return nil
        }
        for faceObservation in faceObservations {
            let boundingBox = faceObservation.boundingBox
            
            let w = boundingBox.width * MetaData.videoWidth
            let h = boundingBox.height * MetaData.videoHeight
            let x = boundingBox.minX * MetaData.videoWidth
//            let y = (1 - boundingBox.minY) * MetaData.videoHeight - h
            let y = boundingBox.minY * MetaData.videoHeight
            
            
            let rect = CGRect(x: x, y: y, width: w, height: h)
            let rectangle = CAShapeLayer()
            rectangle.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
            rectangle.frame = rect
            rectangle.borderWidth = 1.0
            rectangle.borderColor = UIColor.red.cgColor
            
            videoPreviewView.layer.addSublayer(rectangle)
            currentRectangles.append(rectangle)
        }
    }
    
    fileprivate func drawLandmarks(faceObservations: [VNFaceObservation]) {
//        drawRectangles(faceObservations: faceObservations)
        currentLandmarks = currentLandmarks.flatMap {
            landmark in
            landmark.removeFromSuperlayer()
            return nil
        }
        
        for faceObservation in faceObservations {
            guard let landmarks = faceObservation.landmarks else {
                continue
            }
            
            let boundingBox = faceObservation.boundingBox
            let boxW = boundingBox.width * MetaData.videoWidth
            let boxH = boundingBox.height * MetaData.videoHeight
            let boxX = boundingBox.minX * MetaData.videoWidth
//            let boxY = (1 - boundingBox.minY) * MetaData.videoHeight - boxH
            let boxY = boundingBox.minY * MetaData.videoHeight
            
            var regions: [VNFaceLandmarkRegion2D?] = []
            regions.append(landmarks.faceContour)
            regions.append(landmarks.leftEye)
            regions.append(landmarks.rightEye)
            regions.append(landmarks.leftEyebrow)
            regions.append(landmarks.rightEyebrow)
            regions.append(landmarks.nose)
            regions.append(landmarks.noseCrest)
            regions.append(landmarks.medianLine)
            regions.append(landmarks.outerLips)
            regions.append(landmarks.innerLips)
            regions.append(landmarks.leftPupil)
            regions.append(landmarks.rightPupil)
            
            _ = regions.flatMap({ region -> [CGPoint]? in
                guard region != nil else {
                    return nil
                }
                
                let regionLayer = CAShapeLayer()
                
                let path = UIBezierPath()
                var transformedPoints: [CGPoint] = []
                for (index, point) in region!.normalizedPoints.enumerated() {
                    var xRectification: CGFloat = 0
                    var yRectification: CGFloat = 0
                    
                    if point.x < 0.5 {
                        xRectification = 7.5 // (375 - 360) / 2
                    } else if point.x > 0.5 {
                        xRectification = 7.5
                    }
                    if point.y < 0.5 {
                        yRectification = 10.0 + 83.5 // (500 - 480) / 2 + (667 - 500) / 2
                    } else if point.y > 0.5 {
                        yRectification = 10.0 + 83.5
                    }
                    
                    let fooPoint = CGPoint(x: point.x * boxW + boxX + xRectification, y: point.y * boxH + boxY + yRectification)
                    index == 0 ? path.move(to: fooPoint) : path.addLine(to: fooPoint)
                    transformedPoints.append(fooPoint)
                }
                path.lineJoinStyle = .round
                path.lineCapStyle = .round
                regionLayer.path = path.cgPath
                regionLayer.fillColor = nil
                regionLayer.strokeColor = UIColor.green.cgColor
                regionLayer.lineWidth = 1.5
                regionLayer.opacity = 1.0
                regionLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
                regionLayer.frame = videoPreviewLayer.frame
                currentLandmarks.append(regionLayer)
                videoPreviewLayer.addSublayer(regionLayer)

                return transformedPoints
            })
            
        }
    }
    
}

// 相机的 Delegate 实现
extension ViewController: PhotographerDelegate {
    func photographer(_ photographer: Photographer, didCaptureCIImage ciImage: CIImage, at: CMTime) {
        //leftMirrored for front camera
//        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue))
//        self.recognizer.recognizeFaceLandmarksIn(ciImage: ciImageWithOrientation)
    }
    
    func photographer(_ photographer: Photographer, didCapturePhotoBuffer buffer: CVPixelBuffer) {
        //        self.currentBuffer = buffer
        //        print("fuck")
        //        self.recognizer.recognizeFaceIn(buffer: self.currentBuffer!)
    }
    
    func photographer(_ photographer: Photographer, didCaptureVideoBuffer buffer: CVPixelBuffer, at: CMTime) {
                self.currentBuffer = buffer
                //        self.recognizer.recognizeFaceIn(buffer: self.currentBuffer!)
                self.recognizer.recognizeFaceLandmarksIn(buffer: self.currentBuffer!)
    }
    
    
}
