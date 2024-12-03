
//  ModelManager.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/23.
//

import SwiftUI
import Vision


struct PredictObject {

    var xCenter: Float = 0
    var yCenter: Float = 0
    var width: Float = 0
    var height: Float = 0
    var classId: Int = -1
    var confidence: Float = -1
    
}


class PredictionManager {
//    private let model: yolov8n
//    private let mobileNet: MobileNetV2
    private let model: yolo11n_100
//    private let model: YOLOv3
    
    init() {
        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .cpuAndGPU
//            self.model = try yolov8n(configuration: configuration)
//            self.mobileNet = try MobileNetV2(configuration: configuration)
//            self.model = try YOLOv3(configuration: configuration)
            self.model = try yolo11n_100(configuration: configuration)
            print("Model successfully loaded with GPU support.")
        } catch {
            fatalError("Failed to load the CoreML model with GPU support: \(error.localizedDescription)")
        }
        
    }
    
    func predict(image: UIImage, completion: @escaping ([PredictObject]?) -> Void) {
        autoreleasepool {
//            DispatchQueue.global(qos: .userInitiated).async {
                
                var detectedObjects: [PredictObject] = []
//            let targetSize = CGSize(width: 416, height: 416) // 根据模型输入要求设置
            let targetSize = CGSize(width: 640, height: 640) // 根据模型输入要求设置
                if let resizedImage = image.resize(to: targetSize),
                   let pixelBuffer = resizedImage.toCVPixelBuffer() {
                    
                    //                let yolov8Input: yolov8nInput = yolov8nInput(image: pixelBuffer)
//                    let yolov3Input: YOLOv3Input = YOLOv3Input(image: pixelBuffer)
                    let yolo11n_100Input: yolo11n_100Input = yolo11n_100Input(image: pixelBuffer, iouThreshold: 0, confidenceThreshold: 0)
                    do {
                        let results = try self.model.prediction(input: yolo11n_100Input)
//                        let results = try self.model.prediction(input: yolov3Input)
                        //                    print(results.var_914)
                        
                        //                    let detectedObject: PredictObject = self.getObject(predictResult: results.var_914)
                        if (results.coordinates.count != 0) {
                            let detectedObject: PredictObject = self.getObject11(predictResult: results)
//                            let detectedObject: PredictObject = self.getObject3(predictResult: results)
                            //                    print(results.featureNames)
                            //                    print(results.confidence)
                            //                    print(results.confidenceShapedArray)
                            //                    print(results.coordinates.count)
                            //                    print(results.coordinatesShapedArray.count)
                            
                            if(detectedObject.confidence > 0.1) {
                                detectedObjects.append(detectedObject)
                            }
                        }
                        
                        
                    } catch {
                        print("Predict ERROR")
                    }
                }
//                DispatchQueue.main.async {
                    completion(detectedObjects) // 返回检测结果
//                }
//            }
        }
    }
    
    
    func getObject3(predictResult: YOLOv3Output) -> PredictObject {
        var detectedObject: PredictObject = PredictObject()
        
        let coordinates = predictResult.coordinates

        detectedObject.xCenter = 1 - coordinates[1].floatValue
        detectedObject.yCenter = coordinates[0].floatValue
        detectedObject.width = coordinates[3].floatValue
        detectedObject.height = coordinates[2].floatValue
        
//        detectedObject.xCenter = coordinates[0].floatValue
//        detectedObject.yCenter = coordinates[1].floatValue
//        detectedObject.width = coordinates[2].floatValue
//        detectedObject.height = coordinates[3].floatValue
        
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

        return detectedObject
        
    }
    
    func getObject11(predictResult: yolo11n_100Output) -> PredictObject {
        var detectedObject: PredictObject = PredictObject()
        
        let coordinates = predictResult.coordinates
        print(coordinates)
//        let xMin = coordinates[0]
//        let yMin = coordinates[1]
//        let xMax = coordinates[2]
//        let yMax = coordinates[3]
//        let X = (xMax.floatValue - xMin.floatValue) / 2 + xMin.floatValue
//
//
//        let Y = (yMax.floatValue - yMin.floatValue) / 2 + yMin.floatValue

        detectedObject.xCenter = 1 - coordinates[1].floatValue
        detectedObject.yCenter = coordinates[0].floatValue
        detectedObject.width = coordinates[3].floatValue
        detectedObject.height = coordinates[2].floatValue
//        detectedObject.xCenter = coordinates[0].floatValue
//        detectedObject.yCenter = coordinates[1].floatValue
//        detectedObject.width = coordinates[2].floatValue
//        detectedObject.height = coordinates[3].floatValue
        
//        detectedObject.xCenter = Float(width * coordinates[0].floatValue)
//        detectedObject.yCenter = Float(height * coordinates[1].floatValue)
//        detectedObject.width = coordinates[2].floatValue * width
//        detectedObject.height = coordinates[3].floatValue * height
        
        var maxClassConfidence: Float = 0
        var maxClassId: Int = -1
                    
        for i in 0..<11 {
            
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
        
//        var maxClassConfidence: Float = 0
//        var maxClassId: Int = -1
//        for i in 0..<depth {
//            for j in 0..<cols {
//                    
//
//                maxClassConfidence = 0
//                maxClassId = -1
//                for k in 0..<rows {
//
//                    let value = predictResult[[i, k, j] as [NSNumber]].floatValue
//                    print("\(i), \(k), \(j): \(predictResult[[i, k, j] as [NSNumber]])")
////                    print(value)
//                    if (k == 0) {detectedObject.xCenter = value}
//                    else if (k == 1) {detectedObject.yCenter = value}
//                    else if (k == 2) {detectedObject.width = value}
//                    else if (k == 3) {detectedObject.height = value}
//                    else {
////                        print(value)
//                        if (value > maxClassConfidence) {
//                            maxClassConfidence = value
//                            maxClassId = k - 4
//                        }
//                    }
//                }
//                detectedObject.classId = maxClassId
//                detectedObject.confidence = maxClassConfidence
//                print("begin")
//                print("x: \(detectedObject.xCenter)")
//                print("y: \(detectedObject.yCenter)")
//                print("w: \(detectedObject.width)")
//                print("h: \(detectedObject.height)")
//                print("confidence: \(detectedObject.confidence)")
//                print("id: \(detectedObject.classId)")
//            }
//        }

        
        
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
