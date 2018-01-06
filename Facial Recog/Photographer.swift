//
//  Photographer.swift
//  Facial Recog
//
//  Created by Allen X on 8/6/17.
//  Copyright © 2018 allenx. All rights reserved.
//

import Foundation
import AVFoundation
import CoreVideo
import CoreImage

protocol PhotographerDelegate: class {
    func photographer(_ photographer: Photographer, didCapturePhotoBuffer buffer: CVPixelBuffer)
    func photographer(_ photographer: Photographer, didCaptureVideoBuffer buffer: CVPixelBuffer, at: CMTime)
    func photographer(_ photographer: Photographer, didCaptureCIImage ciImage: CIImage, at: CMTime)
}

class Photographer: NSObject {
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: PhotographerDelegate?
    var FPS = 30
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "FacialRecogPhotographerQueue")
    
    var latestTimeStamp = CMTime()
    
    override init() {
        super.init()
    }
    
    func setup(sessionPreset: AVCaptureSession.Preset, completion: @escaping (Bool) -> Void) {
        queue.async {
            self.setupCamera(sessionPreset: sessionPreset) {
                succeeded in
                DispatchQueue.main.async {
                    completion(succeeded)
                }
            }
        }
    }
    
    func setupCamera(sessionPreset: AVCaptureSession.Preset, and completion: (Bool) -> Void) {
        modify(captureSession: captureSession) {
            captureSession.sessionPreset = sessionPreset
            guard let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .front) else {
                completion(false)
                return
            }
            
            // videoInput 对象
            guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                completion(false)
                return
            }
            // 在 session 中加入 videoInput
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            // 摄像头的预览画面（一个 CALayer），可以直接被夹在 view.layer 上
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspect
            self.previewLayer = previewLayer
            
            // videoSettings 是一个字典（键值对），用来定义一些设置，这里设置了摄像头输出视频流的 buffer 数据格式（32BGRA）
            let videoSettings: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA)
            ]
            
            videoOutput.videoSettings = videoSettings
            videoOutput.alwaysDiscardsLateVideoFrames = true
            // 视频的输出需要一个队列（一帧一帧挨个来），这个 queue 是事先生成好的
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            // session 加入 output
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            videoOutput.connection(with: .video)?.videoOrientation = .portrait
            
            // 这是照片数据
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
        }
        completion(true)
    }
    
    func modify(captureSession: AVCaptureSession, closure: () -> ()) {
        captureSession.beginConfiguration()
        closure()
        captureSession.commitConfiguration()
    }
    
    func start() {
        if false == captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func takeAPic() {
        let photoSettings = AVCapturePhotoSettings(format: [
            kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ])
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension Photographer: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil {
            delegate?.photographer(self, didCapturePhotoBuffer: photo.pixelBuffer!)
        }
    }
}

extension Photographer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 当前系统时间戳
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        // 距离上一次提交画面过去的时间
        let deltaTime = timestamp - latestTimeStamp
        // FPS 变量是提前定义好的值，我设置是 30FPS，也就是说每秒钟我的摄像头会获取 30 帧画面给我的神经网络进行处理识别，如果 deltaTime 大于等于了一帧的时间，则意味着当下这一帧应该被反馈到神经网络里了
        if deltaTime >= CMTimeMake(1, Int32(FPS)) {
            // 更新上一次提交画面的时间戳
            latestTimeStamp = timestamp
            // 获取摄像头取到的 Raw Data （CVPixelBuffer）
            let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            
//            let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
//            let ciImage = CIImage(cvImageBuffer: buffer!, options: attachments as! [String : Any]?)
//            delegate?.photographer(self, didCaptureCIImage: ciImage, at: timestamp)
            
            // 让 Photographer 的委托类对这个 buffer 进行处理（这个委托类的 Delegate 方法实现里就会将 buffer 反馈给我的 Recognizer
            delegate?.photographer(self, didCaptureVideoBuffer: buffer!, at: timestamp)
        }
    }
}
