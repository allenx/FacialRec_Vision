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

class ViewController: UIViewController {
    
    var photographer: Photographer!
    
    var currentBuffer: CVPixelBuffer?
    var currentRectangle: [CAShapeLayer] = []
    var currentLandmarks: [CAShapeLayer] = []
    
    var videoPreviewView: UIView!
    
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
                self.videoPreviewView.layer.addSublayer(previewLayer)
                self.photographer.previewLayer?.frame = self.videoPreviewView.bounds
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
            log.error(error!)
        }
    }
}

// 在 View 上，通过检测到的结果绘制矩形框和五官的函数
extension ViewController {
    fileprivate func drawRectangles(faceObservations: [VNFaceObservation]) {
        currentRectangle.flatMap {
            rectangle in
            rectangle.removeFromSuperlayer()
            return nil
        }
        for faceObservation in faceObservations {
            let boundingBox = faceObservation.boundingBox
            
            let w = boundingBox.width * videoPreviewView.frame.size.width
            let h = boundingBox.height * videoPreviewView.frame.size.height
            let x = boundingBox.minX * videoPreviewView.frame.size.width
            let y = (1 - boundingBox.minY) * videoPreviewView.frame.size.height - h
            
            
            let rect = CGRect(x: x, y: y, width: w, height: h)
            let rectangle = CAShapeLayer()
            rectangle.frame = rect
            rectangle.borderWidth = 1.0
            rectangle.borderColor = UIColor.red.cgColor
            
            videoPreviewView.layer.addSublayer(rectangle)
            currentRectangle.append(rectangle)
        }
    }
    
    fileprivate func drawLandmarks(faceObservations: [VNFaceObservation]) {
        drawRectangles(faceObservations: faceObservations)
        currentLandmarks.flatMap {
            landmark in
            landmark.removeFromSuperlayer()
            return nil
        }
        for faceObservation in faceObservations {
            guard let landmarks = faceObservation.landmarks else {
                continue
            }
            
            let boundingBox = faceObservation.boundingBox
            let boxW = boundingBox.width * videoPreviewView.frame.size.width
            let boxH = boundingBox.height * videoPreviewView.frame.size.height
            let boxX = boundingBox.minX * videoPreviewView.frame.size.width
            let boxY = (1 - boundingBox.minY) * videoPreviewView.frame.size.height - boxH
            
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
            
            regions.flatMap({ region -> [CGPoint]? in
                guard region != nil else {
                    return nil
                }
                
                var count = 0
                
                let regionLayer = CAShapeLayer()
                
                let path = UIBezierPath()
                var transformedPoints: [CGPoint] = []
                for (index, point) in region!.normalizedPoints.enumerated() {
                    let fooPoint = CGPoint(x: point.x * boxW + boxX, y: point.y * boxH + boxY)
                    index == 0 ? path.move(to: fooPoint) : path.addLine(to: fooPoint)
                    if count == 0 {
                        log.any(fooPoint)/
                    }
                    transformedPoints.append(fooPoint)
                }
                count += 1
                regionLayer.path = path.cgPath
                regionLayer.fillColor = nil
                regionLayer.strokeColor = UIColor.green.cgColor
                regionLayer.lineWidth = 1.0
                regionLayer.opacity = 1.0
//                var t = CATransform3DIdentity
//                t = CATransform3DRotate(t, CGFloat.pi, 0.5, 1.0, 0.0)
//                regionLayer.transform = t
                regionLayer.transform = CATransform3DMakeRotation(.pi, 0.0, 0.0, 1.0)
                currentLandmarks.append(regionLayer)
                videoPreviewView.layer.addSublayer(regionLayer)
                
                return transformedPoints
            })

        }
    }
    
}

// 相机的 Delegate 实现
extension ViewController: PhotographerDelegate {
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
