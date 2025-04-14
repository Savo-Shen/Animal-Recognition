//
//  CameraDelegate.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/23.
//

import SwiftUI
import AVFoundation
import Vision

protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}


struct CameraViewModel: UIViewControllerRepresentable {
    
    @Binding var predictObject: [PredictObject]?
    @Binding var capturedImage: IdentifiableImage?
    @Binding var isFlashing: Bool
    @Binding var gotObjectList: [GotObject]
    let predictionManger: PredictionManager = PredictionManager()

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, CameraViewControllerDelegate {
        
        let parent: CameraViewModel
        let predictionManager: PredictionManager
        
        init(parent: CameraViewModel, predictionManager: PredictionManager) {
            self.parent = parent
            self.predictionManager = predictionManager
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
            autoreleasepool {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    return
                }
                let ciImage = CIImage(cvImageBuffer: imageBuffer)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let image = UIImage(cgImage: cgImage)
                 
                    predictionManager.predict(image: image) { results in
                        if let results = results, !results.isEmpty {
                            if !self.parent.isFlashing {
                                self.parent.predictObject = results
                            }
                            
                        }
                    }
                }
            }
        }
        
        func didCapturePhoto(_ image: UIImage) {
            print("接收到图片：\(image)")
            if let predictObjectList = self.parent.predictObject {
                for object in predictObjectList {
                    if let croppedImage = cropImage(image: image, object: object) {
                        let gotObject: GotObject = GotObject(predictObject: object, image: croppedImage)
                        self.parent.gotObjectList.append(gotObject)
                    }
                    
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 动画时长
                self.parent.isFlashing = false
            }
        }
        
        func cropImage(image: UIImage, object: PredictObject) -> UIImage? {
            guard let cgImage = image.cgImage else {
                return nil
            }
            let height = CGFloat(cgImage.width)
            let width = CGFloat(cgImage.height)
            
            let w: CGFloat = CGFloat(object.width) * width
            let h: CGFloat = CGFloat(object.height) * height
            let x: CGFloat = CGFloat(object.xCenter) * width - (w / 2)
            let y: CGFloat = CGFloat(object.yCenter) * height - (h / 2)
            
            let cropRect = CGRect(x: x, y: y, width: w, height: h)
            
            return cropImageCore(image: image, to: cropRect)
        }
        
        func cropImageCore(image: UIImage, to rect: CGRect) -> UIImage? {
            guard let cgImage = image.cgImage else {
                return nil
            }
            let adjustedRect = CGRect(
                x: rect.origin.y,
                y: CGFloat(cgImage.height) - (rect.origin.x + rect.size.width),
                width: rect.size.height,
                height: rect.size.width
            )
            if let croppedCGImage = cgImage.cropping(to: adjustedRect) {
                let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
                print("Cropping successful")
                return croppedImage
            } else {
                print("Cropping failed")
            }
            return nil
        }
        
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CameraViewController()
        viewController.coordinator = context.coordinator
        return viewController
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 更新界面
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, predictionManager: predictionManger)
    }
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
   
    var coordinator: CameraViewModel.Coordinator?
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupNotificationObservers()
        
        captureSession = AVCaptureSession()
        
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            print("无法配置摄像头")
            return
        }
        
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            print("无法添加 photoOutput 到 captureSession")
        }
        
        captureSession.addInput(videoDeviceInput)
        
        videoDataOutput = AVCaptureVideoDataOutput()
        
        videoDataOutput.setSampleBufferDelegate(coordinator, queue: DispatchQueue(label: "sample buffer delegate"))
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = self.view.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(videoPreviewLayer)

        DispatchQueue.global(qos: .userInitiated) .async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    func configureFrameRate(for device: AVCaptureDevice, frameRate: Int) {
        do {
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            device.unlockForConfiguration()
        } catch {
            print("Failed to configure frame rate: \(error.localizedDescription)")
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(takePhoto), name: .takePhoto, object: nil)
    }

    @objc private func takePhoto() {
        print("接收到拍照通知")
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        autoreleasepool {
            guard let imageData = photo.fileDataRepresentation(),
            let image = UIImage(data: imageData) else { return }
            print("拍好照片了")
            self.coordinator?.didCapturePhoto(image)
        }
    }
}
