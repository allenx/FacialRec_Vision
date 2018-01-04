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
            
            guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                completion(false)
                return
            }
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspect
//            previewLayer.connection?.videoOrientation = .portrait
            self.previewLayer = previewLayer
            
            
            let videoSettings: [String: Any] = [
//                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32BGRA)
            ]
            
            videoOutput.videoSettings = videoSettings
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            videoOutput.connection(with: .video)?.videoOrientation = .portrait
            
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
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - latestTimeStamp
        if deltaTime >= CMTimeMake(1, Int32(FPS)) {
            latestTimeStamp = timestamp
            let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)

//            let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
//            let ciImage = CIImage(cvImageBuffer: buffer!, options: attachments as! [String : Any]?)
            
//            delegate?.photographer(self, didCaptureCIImage: ciImage, at: timestamp)
            delegate?.photographer(self, didCaptureVideoBuffer: buffer!, at: timestamp)
        }
    }
}
