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
    
    var didDetectAllen: Bool = false
    
    var videoPreviewView: UIView!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    let commandGroup = DispatchGroup()
    
    
    var recognizer: Recognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        videoPreviewView = UIView(frame: view.frame)
        view.addSubview(videoPreviewView)
        
        // 初始化一个 initializer，并且把回调函数传给里面的各种 request
        recognizer = Recognizer(
            landmarksCompletionBlock: self.didFinishLandmarksRecog,
            faceCompletionBlock: self.didFinishFaceRecog,
            allenCompletionBlock: self.didFinishDetectingAllen,
            openFaceCompletionBlock: self.didFinishDetectingAllen_OpenFace_SVM
        )
        
        
        // 初始化相机
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

extension ViewController {
    
    // 使用 Vision 检测人脸的回调函数
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
    
    // 使用 Vision 检测 Face Landmarks 的回调函数
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
    
    // 使用 allenNet 检测 Allen（我）的回调函数
    fileprivate func didFinishDetectingAllen(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNClassificationObservation] {
            if let best = results.first {
                if best.identifier.starts(with: "Allen") && best.confidence >= 0.7 {
                    didDetectAllen = true
                }
            } else {
                log.word("oops")/
            }
        } else {
            didDetectAllen = false
            log.error(error!)/
        }
    }
    
    // 使用 OpenFace 检测 Allen（我）的回调函数（使用我训练的 SVM（OFClassifier）用于归类）
    fileprivate func didFinishDetectingAllen_OpenFace_SVM(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNCoreMLFeatureValueObservation] {
            let embeddings = results.first?.featureValue.multiArrayValue
            let embeddingsArray = embeddings?.array(type: Double.self)
            
            // 方法一： 载入训练好的 SVM 分类器模型，对 OpenFace 产生的 128 值进行分类
            let classifier = OFClassifier()
            do {
                let results = try classifier.prediction(input: embeddings!)
                if results.classLabel == 1 && results.classProbability[results.classLabel]! >= 0.7 {
                    didDetectAllen = true
                }
            } catch {
                didDetectAllen = false
                log.error(error)/
            }
        }
    }
    
    // 使用 OpenFace 检测 Allen（我）的回调函数（使用我的矩阵运算库进行匹配）
    fileprivate func didFinishDetectingAllen_OpenFace_Matrix(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNCoreMLFeatureValueObservation] {
            let embeddings = results.first?.featureValue.multiArrayValue
            let embeddingsArray = embeddings?.array(type: Double.self)
            
            // 方法二： 矩阵运算找到匹配度最高的那个
            let embeddingsVector = Vector(flatValues: embeddingsArray!)
            var embeddingsMatrix = Matrix(rowCount: 1, columnCount: 128, flat: embeddingsVector)
            // 读取训练好的 labels 和 reps 数据并将它们初始化为数组/矩阵
            guard let labelsPath = Bundle.main.path(forResource: "labels", ofType: "csv") else {
                return
            }
            guard let repsPath = Bundle.main.path(forResource: "reps", ofType: "csv") else {
                return
            }
            let labels = try! String(contentsOfFile: labelsPath, encoding: String.Encoding.utf8)
            let reps = try! String(contentsOfFile: repsPath, encoding: String.Encoding.utf8)
            let labelsArray: [String] = labels.components(separatedBy: "\r")
                .filter {
                    $0.count > 0
                }.map {
                    return $0.components(separatedBy: "/")[3]
            }
            
            let repsArray: [[Double]] = reps
                .components(separatedBy: "\r")
                .filter { $0.count > 0 }
                .map { return $0.components(separatedBy: ",").map{ Double($0)! } }
            var flatArray: [Double] = []
            for row in repsArray {
                flatArray += row
            }
            let flat = Vector(flatValues: flatArray)
            let repsMatrix = Matrix(rowCount: repsArray.count, columnCount: repsArray[0].count, flat: flat)
            // 求两个矩阵的 diff
            let diff = repsMatrix - embeddingsMatrix
            
            // Find the min diff. Need new rules
        } else {
            didDetectAllen = false
        }
    }
}

// 在 View 上，通过检测到的结果绘制矩形框和五官的函数
extension ViewController {
    
    // 绘制矩形框
    fileprivate func drawRectangles(faceObservations: [VNFaceObservation]) {
        currentRectangles = currentRectangles.flatMap {
            rectangle in
            rectangle.removeFromSuperlayer()
            return nil
        }
        for faceObservation in faceObservations {
            let boundingBox = faceObservation.boundingBox
            
            let w = boundingBox.width * 375
            let h = boundingBox.height * 500
            let x = boundingBox.minX * 375 - 7.5
            let y = (1 - boundingBox.minY) * 500 - h + 83.5 + 10
            //            let y = boundingBox.minY * MetaData.videoHeight
            
            
            let rect = CGRect(x: x, y: y, width: w, height: h)
            let rectangle = CAShapeLayer()
            rectangle.frame = rect
            //            rectangle.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
            rectangle.borderWidth = 1.0
            rectangle.borderColor = UIColor.red.cgColor
            
            videoPreviewView.layer.addSublayer(rectangle)
            currentRectangles.append(rectangle)
        }
    }
    
    // 绘制 face landmarks
    fileprivate func drawLandmarks(faceObservations: [VNFaceObservation]) {
        //        drawRectangles(faceObservations: faceObservations)
        // 将上一帧一里面显示在 UI 上的检测结果删掉
        currentLandmarks = currentLandmarks.flatMap {
            landmark in
            landmark.removeFromSuperlayer()
            return nil
        }
        
        // 对每一张检测到的人脸做：
        for faceObservation in faceObservations {
            guard let landmarks = faceObservation.landmarks else {
                continue
            }
            
            // 计算出人脸的区域（从 Vision 的表示值计算到正常 UIKit 中的值）
            let boundingBox = faceObservation.boundingBox
            let boxW = boundingBox.width * MetaData.videoWidth
            let boxH = boundingBox.height * MetaData.videoHeight
            let boxX = boundingBox.minX * MetaData.videoWidth
            //            let boxY = (1 - boundingBox.minY) * MetaData.videoHeight - boxH
            let boxY = boundingBox.minY * MetaData.videoHeight
            
            // didDetectAllen 是神经网络会改变的值，如果神经网络检测到了 Allen（我），
            // 那么 didDetectAllen 则是 true
            if didDetectAllen {
                // 名字标签
                let nameLabel = UILabel(text: "Allen", fontSize: 14)
                nameLabel.tag = 9
                nameLabel.textColor = .white
                // 头像标签
                let avatarView = UIImageView(imageName: "allen", desiredSize: CGSize(width: 50, height: 50))
                avatarView?.tag = 10
                avatarView?.frame = CGRect(x: boxX+boxW+10, y: (1 - boundingBox.minY) * MetaData.videoHeight - boxH, width: 50, height: 50)
                nameLabel.frame = CGRect(x: boxX+boxW+10, y: (avatarView?.frame.origin.y)!+56, width: 66, height: 14)
                for subview in videoPreviewView.subviews {
                    if subview.tag == 9 || subview.tag == 10 {
                        subview.removeFromSuperview()
                    }
                }
                videoPreviewView.addSubview(avatarView!)
                videoPreviewView.addSubview(nameLabel)
            }
            
            // 将检测到的 11 个脸上区域（face landmarks）加入到 regions 数组
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
            
            // 遍历 regions 数组，并做事情
            _ = regions.flatMap({ region -> [CGPoint]? in
                guard region != nil else {
                    return nil
                }
                // 建立一个 CALayer
                let regionLayer = CAShapeLayer()
                // 建立贝塞尔曲线
                let path = UIBezierPath()
                var transformedPoints: [CGPoint] = []
                
                // 对 Vision 中的坐标值进行转换和矫正
                for (index, point) in region!.normalizedPoints.enumerated() {
                    
                    // 用于矫正的魔数
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
                
                // 画贝塞尔曲线（把这些点连接起来）
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
                // 在视频预览图层上加上这个人脸检测结果
                videoPreviewLayer.addSublayer(regionLayer)
                
                return transformedPoints
            })
            
            // 这里可以用来输出成 UIImage 再输出成文件
            //            UIGraphicsBeginImageContextWithOptions(videoPreviewView.frame.size, false, 0)
            //            for layer in currentLandmarks {
            //                layer.render(in: UIGraphicsGetCurrentContext()!)
            //            }
            //            let image = UIGraphicsGetImageFromCurrentImageContext()
            //            UIGraphicsEndImageContext()
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
        //        self.recognizer.recognizeFaceIn(buffer: self.currentBuffer!)
    }
    
    func photographer(_ photographer: Photographer, didCaptureVideoBuffer buffer: CVPixelBuffer, at: CMTime) {
        self.currentBuffer = buffer
        //        self.recognizer.recognizeFaceIn(buffer: self.currentBuffer!)
        //        self.recognizer.recognizeFaceLandmarksIn(buffer: self.currentBuffer!)
        self.recognizer.recognizeAllenWithOpenFaceIn(buffer: self.currentBuffer!)
    }
}
