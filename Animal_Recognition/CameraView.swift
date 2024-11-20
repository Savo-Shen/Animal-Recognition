//
//  CameraView.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/17.
//

import SwiftUI
import AVFoundation
import Vision

struct PredictObject {

    var xCenter: Float = 0
    var yCenter: Float = 0
    var width: Float = 0
    var height: Float = 0
    var classId: Int = -1
    var confidence: Float = -1
    
}

protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}

// 这个类将包装 AVFoundation 的 AVCaptureSession 用于 SwiftUI
// SwiftUI是声明式框架，本身不提供UIViewController类型的视图
// UIViewControllerRepresentable: 用于将UIViewController从UIKit引入到SwiftUI
struct CameraView: UIViewControllerRepresentable {
    
    @Binding var predictObject: PredictObject?
    @Binding var capturedImage: IdentifiableImage?
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
                            for result in results {
                                print("Detected: \(result.classId) - Confidence: \(result.confidence)")
                                print("w: \(result.width) - h: \(result.height)")
                                self.parent.predictObject = result
                            }
                        } else {
                            self.parent.predictObject = PredictObject(xCenter: 0, yCenter: 0, width: 0, height: 0, classId: -1, confidence: 0)
                            print("No objects detected or prediction failed.")
                        }
                    }
                }
            }
            

        }
        
        func didCapturePhoto(_ image: UIImage) {
            print("接收到图片：\(image)")
            DispatchQueue.main.async {
//                一定要变capturedImage，不然UUID不会变所以就不会更新。
                self.parent.capturedImage = IdentifiableImage(image: image)
            }
            print("主页面的 capturedImage 是否更新：\(String(describing: self.parent.capturedImage))")
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
            DispatchQueue.global(qos: .userInitiated) .async {
                DispatchQueue.main.async {
                    print("拍好照片了")
                    self.coordinator?.didCapturePhoto(image)
                }
            }
        }

    }

}

class PredictionManager {
    private let model: yolov8n
    private let mobileNet: MobileNetV2
    private let model3: YOLOv3
    
    init() {
        do {
            let configuration = MLModelConfiguration()
            self.model = try yolov8n(configuration: configuration)
            self.mobileNet = try MobileNetV2(configuration: configuration)
            self.model3 = try YOLOv3(configuration: configuration)
        } catch {
            fatalError("Failed to load the CoreML model: \(error.localizedDescription)")
        }
        
    }
    
    func predict(image: UIImage, completion: @escaping ([PredictObject]?) -> Void) {
        autoreleasepool {
            DispatchQueue.global(qos: .userInitiated).async {
                
                var detectedObjects: [PredictObject] = []
                let targetSize = CGSize(width: 416, height: 416) // 根据模型输入要求设置
                if let resizedImage = image.resize(to: targetSize),
                   let pixelBuffer = resizedImage.toCVPixelBuffer() {
                    
                    //                let yolov8Input: yolov8nInput = yolov8nInput(image: pixelBuffer)
                    let yolov3Input: YOLOv3Input = YOLOv3Input(image: pixelBuffer)
                    do {
                        let results = try self.model3.prediction(input: yolov3Input)
                        //                    print(results.var_914)
                        
                        //                    let detectedObject: PredictObject = self.getObject(predictResult: results.var_914)
                        if (results.coordinates.count != 0) {
                            let detectedObject: PredictObject = self.getObject3(predictResult: results)
                            //                    print(results.featureNames)
                            //                    print(results.confidence)
                            //                    print(results.confidenceShapedArray)
                            //                    print(results.coordinates.count)
                            //                    print(results.coordinatesShapedArray.count)
                            
                            if(detectedObject.confidence > 0.5) {
                                detectedObjects.append(detectedObject)
                            }
                        }
                        
                        
                    } catch {
                        print("Predict ERROR")
                    }
                }
                DispatchQueue.main.async {
                    completion(detectedObjects) // 返回检测结果
                }
            }
        }
    }
    
    func getObject3(predictResult: YOLOv3Output) -> PredictObject {
        var detectedObject: PredictObject = PredictObject()
        
        let coordinates = predictResult.coordinates
        
//        let xMin = coordinates[0]
//        let yMin = coordinates[1]
//        let xMax = coordinates[2]
//        let yMax = coordinates[3]
//        let X = (xMax.floatValue - xMin.floatValue) / 2 + xMin.floatValue
//        
//
//        let Y = (yMax.floatValue - yMin.floatValue) / 2 + yMin.floatValue

        detectedObject.xCenter = coordinates[0].floatValue
        detectedObject.yCenter = coordinates[1].floatValue
        detectedObject.width = coordinates[2].floatValue
        detectedObject.height = coordinates[3].floatValue
        
//        detectedObject.xCenter = Float(width * coordinates[0].floatValue)
//        detectedObject.yCenter = Float(height * coordinates[1].floatValue)
//        detectedObject.width = coordinates[2].floatValue * width
//        detectedObject.height = coordinates[3].floatValue * height
        
        var maxClassConfidence: Float = 0
        var maxClassId: Int = -1
                    
        for i in 0..<80 {
            
            if (predictResult.confidence[i].floatValue > maxClassConfidence) {
                maxClassConfidence = predictResult.confidence[i].floatValue
                maxClassId = i
            }

        }
        
        detectedObject.classId = maxClassId
        detectedObject.confidence = Float(maxClassConfidence)
//        print(maxClassId)
        return detectedObject
        
    }
    
    func getObject(predictResult: MLMultiArray) -> PredictObject {
        var detectedObject: PredictObject = PredictObject()
        let shape = predictResult.shape
        let depth = shape[0].intValue
        let rows = shape[1].intValue
        let cols = shape[2].intValue
        
//        // 解析每个框的输出
//        for boxIndex in 0..<cols {
//            // 计算当前框的起始位置
//            let startIndex = boxIndex * rows
//            let endIndex = startIndex + rows
//            
//            // 从 MLMultiArray 中提取当前框的数据
//            // 手动提取当前框的数据，逐个元素访问
//            var boxData: [NSNumber] = []
//            for i in startIndex..<endIndex {
//                boxData.append(predictResult[i])
//            }
//            
//            // 提取 xywh 坐标 (前 4 个值)
//            let xCenter = boxData[0].floatValue
//            let yCenter = boxData[1].floatValue
//            let width = boxData[2].floatValue
//            let height = boxData[3].floatValue
//            
//            // 提取类别概率 (后 80 个值)
//            let classProbabilities = Array(boxData[4..<84])
//            
//            // 找到最大类别概率的索引（即预测的类别）
//            if let maxClassIndex = classProbabilities.indices.max(by: { classProbabilities[$0].floatValue < classProbabilities[$1].floatValue }) {
//                let maxClassProbability = classProbabilities[maxClassIndex]
//                
//                // 输出结果
//                print("Detected box \(boxIndex):")
//                print("xywh: (\(xCenter), \(yCenter), \(width), \(height))")
//                print("Predicted class: \(maxClassIndex) with probability: \(maxClassProbability)")
//            }
//        }
        
        var maxClassConfidence: Float = 0
        var maxClassId: Int = -1
        for i in 0..<depth {
            for j in 0..<cols {
                    

                maxClassConfidence = 0
                maxClassId = -1
                for k in 0..<rows {

                    let value = predictResult[[i, k, j] as [NSNumber]].floatValue
                    print("\(i), \(k), \(j): \(predictResult[[i, k, j] as [NSNumber]])")
//                    print(value)
                    if (k == 0) {detectedObject.xCenter = value}
                    else if (k == 1) {detectedObject.yCenter = value}
                    else if (k == 2) {detectedObject.width = value}
                    else if (k == 3) {detectedObject.height = value}
                    else {
//                        print(value)
                        if (value > maxClassConfidence) {
                            maxClassConfidence = value
                            maxClassId = k - 4
                        }
                    }
                }
                detectedObject.classId = maxClassId
                detectedObject.confidence = maxClassConfidence
                print("begin")
                print("x: \(detectedObject.xCenter)")
                print("y: \(detectedObject.yCenter)")
                print("w: \(detectedObject.width)")
                print("h: \(detectedObject.height)")
                print("confidence: \(detectedObject.confidence)")
                print("id: \(detectedObject.classId)")
            }
        }

        
        
        return detectedObject
    }
//
//    func predict(image: UIImage, completion: @escaping ([VNRecognizedObjectObservation]?) -> Void) {
//        DispatchQueue.global(qos: .userInitiated).async {
//            var detectedObjects: [VNRecognizedObjectObservation] = []
//            let targetSize = CGSize(width: 640, height: 640) // 根据模型输入要求设置
//            if let resizedImage = image.resize(to: targetSize),
//               let pixelBuffer = resizedImage.toCVPixelBuffer() {
//                
//                do {
//                    let visionModel = try VNCoreMLModel(for: self.model.model)
//                    
//                    let request = VNCoreMLRequest(model: visionModel) { request, error in
//                        if let error = error {
//                            print("Error during request: \(error.localizedDescription)")
//                            DispatchQueue.main.async {
//                                completion(nil)
//                            }
//                            return
//                        }
//                        
//                        guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
//                            print("Failed to cast results to VNRecognizedObjectObservation.")
//                            DispatchQueue.main.async {
//                                completion(nil)
//                            }
//                            return
//                        }
//                        
//                        // 假设模型输出的是多维数组
//                        if let multiArray = results.first?.featureValue.multiArrayValue {
//                            
//                            let numBoxes = multiArray.shape[0].intValue // 假设多维数组的第一个维度是预测框数量
//                            let numClasses = 80
//                            
//                            for i in 0..<numBoxes {
//                                
//                                let baseIndex = 0
//                                
//                                let x_center = multiArray[baseIndex + 0].floatValue
//                                let y_center = multiArray[baseIndex + 1].floatValue
//                                let width = multiArray[baseIndex + 2].floatValue
//                                let height = multiArray[baseIndex + 3].floatValue
//                                
//                                // 获取类别的置信度（每个类别的概率）
//                                var maxClassConfidence: Float = 0
//                                var maxClassId: Int = -1
//                                for j in 0..<numClasses {
//                                    let classConfidence = multiArray[baseIndex + 5 + j].floatValue
//                                    if classConfidence > maxClassConfidence {
//                                        maxClassConfidence = classConfidence
//                                        maxClassId = j
//                                    }
//                                }
//                                
//                                // 如果最大类别置信度超过阈值，保存检测框
//                                if maxClassConfidence > 0.5 {
//                                    print(maxClassId)
//                                    let boundingBox = CGRect(x: CGFloat(x_center), y: CGFloat(y_center), width: CGFloat(width), height: CGFloat(height))
//                                    let observation = VNRecognizedObjectObservation(boundingBox: boundingBox)
//                                    detectedObjects.append(observation)
//                                }
//                            }
//                        }
//                        
//                        DispatchQueue.main.async {
//                            completion(detectedObjects) // 返回检测结果
//                        }
//                    }
//                    
//                    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
//                    try handler.perform([request])
//                    
//                } catch {
//                    print("Error setting up CoreML model: \(error.localizedDescription)")
//                    DispatchQueue.main.async {
//                        completion(nil)
//                    }
//                }
//            }
//        }
//    }
//    // 识别处理
//    func drawVisionRequestResults(_ results: [Any]) {
//        for observation in results where observation is VNRecognizedObjectObservation {
//            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
//                continue
//            }
//
//            let topLabelObservation = objectObservation.labels[0]
////            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
//            print("置信度：", topLabelObservation.confidence)
//            print("内容：", topLabelObservation.identifier)
////            print("边框", objectBounds)
//        }
//    }
        

//    private func processMultiArray(_ array: MLMultiArray) -> [VNRecognizedObjectObservation] {
//        let numberOfClasses = 84
//        let numberOfDetections = 8400
//        var detectedObjects: [VNRecognizedObjectObservation] = []
//
//        for i in 0..<numberOfDetections {
//            // 解包置信度
//            if let confidence = array[[NSNumber(value: 0), NSNumber(value: i), NSNumber(value: 0)]]?.floatValue, confidence > 0.5 {
//                // 解包边界框
//                guard let x1 = array[[NSNumber(value: 0), NSNumber(value: i), NSNumber(value: 1)]]?.floatValue,
//                      let y1 = array[[NSNumber(value: 0), NSNumber(value: i), NSNumber(value: 2)]]?.floatValue,
//                      let x2 = array[[NSNumber(value: 0), NSNumber(value: i), NSNumber(value: 3)]]?.floatValue,
//                      let y2 = array[[NSNumber(value: 0), NSNumber(value: i), NSNumber(value: 4)]]?.floatValue else {
//                    continue
//                }
//
//                // 创建边界框
//                let boundingBox = CGRect(
//                    x: CGFloat(x1),
//                    y: CGFloat(y1),
//                    width: CGFloat(x2 - x1),
//                    height: CGFloat(y2 - y1)
//                )
//
//                // 将结果保存
//                let observation = VNRecognizedObjectObservation(boundingBox: boundingBox)
//                detectedObjects.append(observation)
//            }
//        }
//
//        return detectedObjects
//    }

}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?

        let width = Int(self.size.width)
        let height = Int(self.size.height)

        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32ARGB, attrs,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        let data = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
    
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
//        UIGraphicsGetImageFromCurrentImageContext()返回的是UIImage
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

}
