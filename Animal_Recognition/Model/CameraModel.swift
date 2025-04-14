
//  ModelManager.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/23.
//

import SwiftUI
import Vision


struct PredictObject {

    let Id: UUID = UUID()
    
    var xCenter: Float = 0
    var yCenter: Float = 0
    var width: Float = 0
    var height: Float = 0
    var classId: Int = -1
    var confidence: Float = -1
    
}


class PredictionManager {
    
    private let model: yolov11m80_640
    
    init() {
        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .cpuAndGPU
            self.model = try yolov11m80_640(configuration: configuration)
        } catch {
            fatalError("Failed to load the CoreML model with GPU support: \(error.localizedDescription)")
        }
    }
    
    func predict(image: UIImage, completion: @escaping ([PredictObject]?) -> Void) {
        autoreleasepool {
            var detectedObjects: [PredictObject] = []
            let targetSize = CGSize(width: 640, height: 640)
            if let resizedImage = image.resize(to: targetSize),
               let pixelBuffer = resizedImage.toCVPixelBuffer() {
                let yolov11m80_640Input: yolov11m80_640Input = yolov11m80_640Input(image: pixelBuffer, iouThreshold: 0.45, confidenceThreshold: 0.25)
                do {
                    let results = try self.model.prediction(input: yolov11m80_640Input)
                    if (results.coordinates.count != 0) {
                        detectedObjects = self.getObject11m(predictResult: results)
                    }
                } catch {
                    print("Predict ERROR")
                }
            }
            completion(detectedObjects)
        }
    }
    
    func getObject11m(predictResult: yolov11m80_640Output) -> [PredictObject] {
        var detectedObjectList: [PredictObject] = [];
        let numClass = 80
        let coordinates = predictResult.coordinates
        let num = (coordinates.count / 4) - 1
        for i in (0...num) {
            var detectedObject: PredictObject = PredictObject()
            detectedObject.xCenter = 1 - coordinates[1 + i*4].floatValue
            detectedObject.yCenter = coordinates[0 + i*4].floatValue
            detectedObject.width = coordinates[3 + i*4].floatValue
            detectedObject.height = coordinates[2 + i*4].floatValue
            
            var maxClassConfidence: Float = 0
            var maxClassId: Int = -1

            for j in 0..<numClass {
                if (predictResult.confidence[j + i*numClass].floatValue > maxClassConfidence) {
                    maxClassConfidence = predictResult.confidence[j + i*numClass].floatValue
                    maxClassId = j % numClass
                }
            }
            detectedObject.classId = maxClassId
            detectedObject.confidence = Float(maxClassConfidence)
            detectedObjectList.append(detectedObject)
        }
        return detectedObjectList
    }
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
        let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        context?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
    
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

}
