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

// 这个类将包装 AVFoundation 的 AVCaptureSession 用于 SwiftUI
// SwiftUI是声明式框架，本身不提供UIViewController类型的视图
// UIViewControllerRepresentable: 用于将UIViewController从UIKit引入到SwiftUI
struct CameraView: UIViewControllerRepresentable {
    
    @Binding var predictObject: [PredictObject]?
    @Binding var capturedImage: IdentifiableImage?
    @Binding var isFlashing: Bool
    @Binding var gotObjectList: [GotObject]
    let predictionManger: PredictionManager = PredictionManager()
//    Coordinator：通常用于桥接UIKit和SwiftUI之间的交互。
//    NSObject：用于和Objective-C API交互，例如UIKit
//    AVCaptureVideoDataOutputSampleBufferDelegate： 是iOS中AVCaptureSession的一个协议，用于处理摄像头数据流的每一帧
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, CameraViewControllerDelegate {
        
        let parent: CameraView
        let predictionManager: PredictionManager
        
        init(parent: CameraView, predictionManager: PredictionManager) {
            self.parent = parent
            self.predictionManager = predictionManager
        }
        
        // 获取每一帧的图像数据
//        captureOutput：当AVCaptureSession捕捉到心得视频帧时会调用这个方法，每获得一帧九调用这个方法
//        sampleBuffer就是视频帧数据
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
//            print(sampleBuffer)
            // 这里你可以处理每一帧的图像数据
            // 将其转换为 UIImage
            autoreleasepool {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    return
                }
                let ciImage = CIImage(cvImageBuffer: imageBuffer)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let image = UIImage(cgImage: cgImage)
                    // 这里你可以做进一步处理或更新 UI
                    
    //                var result: PredictObject = PredictObject()
    //                result.xCenter = 100
    //                result.yCenter = 100
    //                result.height = 100
    //                result.width = 100
    //                result.classId = 1
    //                result.confidence = 0.8
    //                self.parent.predictObject = result
    //                print(self.parent.predictObject)
                    predictionManager.predict(image: image) { results in
                        if let results = results, !results.isEmpty {
//                            for result in results {
//                                print("Detected: \(result.classId) - Confidence: \(result.confidence)")
//                                print("x: \(result.xCenter) - y: \(result.yCenter)")
//                                print("w: \(result.width) - h: \(result.height)")
//                            }
                            if !self.parent.isFlashing {
                                self.parent.predictObject = results
                            }
                            
                        } else {
//                            self.parent.predictObject = PredictObject(xCenter: 0, yCenter: 0, width: 0, height: 0, classId: -1, confidence: 0)
//                            self.parent.predictObject = []
//                            print("No objects detected or prediction failed.")
                        }
                    }
                }
            }
            

        }
        
        func didCapturePhoto(_ image: UIImage) {
            print("接收到图片：\(image)")
//                一定要变capturedImage，不然UUID不会变所以就不会更新。
            
            if let predictObjectList = self.parent.predictObject {
                for object in predictObjectList {
                    if let croppedImage = cropImage(image: image, object: object) {
                        let gotObject: GotObject = GotObject(predictObject: object, image: croppedImage)
                        self.parent.gotObjectList.append(gotObject)
                    }
                    
                }
//                self.parent.capturedImage = IdentifiableImage(image: image)
                
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 动画时长
                self.parent.isFlashing = false
            }
            
//            print("主页面的 capturedImage 是否更新：\(String(describing: self.parent.capturedImage))")
        }
        
        func cropImage(image: UIImage, object: PredictObject) -> UIImage? {
            guard let cgImage = image.cgImage else {
                return nil
            }
            let height = CGFloat(cgImage.width)
            let width = CGFloat(cgImage.height)
//            cgImage 的坐标系起点为左上角，而 UIKit 或 SwiftUI 的坐标系起点为左下角。如果你直接使用 UIKit 或 SwiftUI 的 CGRect，需要将 y 值调整：
            print(object)
            print(width)
            print(object.width)
            print(height)
            print(object.height)
            
            let w: CGFloat = CGFloat(object.width) * width
            let h: CGFloat = CGFloat(object.height) * height
            let x: CGFloat = CGFloat(object.xCenter) * width - (w / 2)
            let y: CGFloat = CGFloat(object.yCenter) * height - (h / 2)
            
            let cropRect = CGRect(x: x, y: y, width: w, height: h)
            
            return cropImageCore(image: image, to: cropRect)
        }
        
        func cropImageCore(image: UIImage, to rect: CGRect) -> UIImage? {
//            let scale = UIScreen.main.scale
            guard let cgImage = image.cgImage else {
                return nil
            }
//            let adjustedY = CGFloat(cgImage.height) - rect.origin.y - rect.size.height
//            let adjustedRect = CGRect(
//                x: rect.origin.y,
//                y: CGFloat(cgImage.width) - (rect.origin.x + rect.size.width),
//                width: rect.size.height,
//                height: rect.size.width
//            )
//            cgImgae.width是长的
            let adjustedRect = CGRect(
                x: rect.origin.y,
                y: CGFloat(cgImage.height) - (rect.origin.x + rect.size.width),
                width: rect.size.height,
                height: rect.size.width
            )
//            print("rect")
//            print(rect)
//            print("adjustedRect")
//            print(adjustedRect)
//            print("cgImage")
//            print(cgImage.width)
//            print(cgImage.height)
//            if adjustedRect.origin.x >= 0, adjustedRect.origin.y >= 0,
//               adjustedRect.width > 0, adjustedRect.height > 0,
//               adjustedRect.origin.x + adjustedRect.width <= CGFloat(cgImage.width),
//               adjustedRect.origin.y + adjustedRect.height <= CGFloat(cgImage.height) {
            if let croppedCGImage = cgImage.cropping(to: adjustedRect) {
                let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
                print("Cropping successful")
                // 转换回 UIImage
                return croppedImage
            } else {
                print("Cropping failed")
            }
//            } else {
//                print("Rect is out of bounds or invalid")
//            }
//            // 使用 CGRect 裁剪图像
//            guard let croppedCGImage = cgImage.cropping(to: rect) else {
//                print("no good 2")
//                return nil
//            }
            return nil
        }
        
    }
    
//    主要方法，用于返回UIViewController的实例，将coordinator设置为当前Coordinator实例
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = CameraViewController()
//        在这里声明Controller类，然后指定他的委托为自己。
        viewController.coordinator = context.coordinator
        return viewController
    }
//    主要方法，用于更新已经创建的UIViewController
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 更新界面
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self, predictionManager: predictionManger)
    }
}



// UIViewController， UIKit框架中的核心类，用于管理应用中的一个屏幕或界面。
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
   
    var coordinator: CameraView.Coordinator?
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    
//    类的生命周期方法，在视图加载后执行
    override func viewDidLoad() {
        
        super.viewDidLoad()
//        注册观察者
        setupNotificationObservers()
        
        // 设置 AVCaptureSession
        captureSession = AVCaptureSession()
        
//        配置相机输入设备
//AVCaptureDevice.default(for: .video)： 获取默认的视频设备（即摄像头）
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            print("无法配置摄像头")
            return
        }
        
//          配置拍照输出
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            print("无法添加 photoOutput 到 captureSession")
        }
        
        captureSession.addInput(videoDeviceInput)
        
        // 设置输出数据
        videoDataOutput = AVCaptureVideoDataOutput()
//        将每一帧都传递给Coordinator处理，即传到SwiftUI里的类
        videoDataOutput.setSampleBufferDelegate(coordinator, queue: DispatchQueue(label: "sample buffer delegate"))
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        // 配置摄像头预览
//        AVCaptureVideoPreviewLayer 用于将捕获的摄像头视频显示在屏幕上。
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = self.view.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(videoPreviewLayer)
        
        // 开始捕捉
        // DispatchQueue.global(qos: .userInitiated):表示这是一个全局的并发队列，通常用于执行后台任务
//         制定队列的 质量服务（Quality of Service， QoS），QoS用来描述任务的优先级
//        .userInitiated指用户发起的任务，通常项应急比较高
//        •    .userInteractive：最高优先级，UI 相关的任务，比如动画、手势处理。
//        •    .background：最低优先级，用于不需要立即完成的任务，比如文件下载、后台同步等。
//        •    .utility：适用于一些长期运行但不需要快速完成的任务，如数据处理、网络请求等。
//        .async:表示为异步执行。
        DispatchQueue.global(qos: .userInitiated) .async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning() // 停止摄像头
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
    
//    接收Notification的信息
    private func setupNotificationObservers() {
//        从default中接收信息，监听.takePhoto变量，如果有，就调用takePhoto函数。
        NotificationCenter.default.addObserver(self, selector: #selector(takePhoto), name: .takePhoto, object: nil)
    }

//    @objc：表示能被Objective-C调用，因为通知系统是基于Objective-C的
    @objc private func takePhoto() {
        print("接收到拍照通知")
//AVCapturePhotoSettings：用于配置拍照时的设置。
        let settings = AVCapturePhotoSettings()
//        设置自动开启闪光灯
        settings.flashMode = .auto
//        负责捕捉静态照片
//        with： setting负责传入这次拍照的设置
//        delegate：self 制定当前对象作为委托对象，意味着self会负责回调
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        autoreleasepool {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }
    //        将图像处理放到后台线程
//            DispatchQueue.global(qos: .userInitiated) .async {
//                DispatchQueue.main.async {
                    print("拍好照片了")
                    
                    self.coordinator?.didCapturePhoto(image)
//                }
//            }
        }

    }

}
