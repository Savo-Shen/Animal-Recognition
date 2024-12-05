//
//  ContentView.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/16.
//

import SwiftUI

// 因为UIImage不具有唯一标识符，所以为其创造一个结构体，使其具有UUID就可以用于.sheet的触发
struct IdentifiableImage: Identifiable {
    var id = UUID()
    var image: UIImage
    
    // 实现 Equatable 协议的 `==` 操作符，比较两个 IdentifiableImage 是否相等
//类似自定sort里的cmp函数一样
    static func == (lhs: IdentifiableImage, rhs: IdentifiableImage) -> Bool {
        return lhs.id == rhs.id && lhs.image == rhs.image
    }
}

struct ContentView: View {
//  @State修饰的变量在改变后会重新渲染画面
//  UIImage 是 UIKit 框架中的一个类，用于表示和操作图像（如 PNG、JPEG）。
//  ? 表示这个变量是个可选类型(不确定它当前是否有值)，只有有问号这个变量才可以是nil
//  nil就是空类似NULL
    @State private var capturedImage: IdentifiableImage? = nil
//    @State private var predictObject: PredictObject? = PredictObject(xCenter: 220, yCenter: 450, width: 440, height: 890)
    @State private var predictObject: [PredictObject]? = nil
    @State private var isCameraActive = true
    
    var body: some View {
        NavigationView {
            ZStack {
                if isCameraActive {

//                    ResultView()
                    CameraView(predictObject: $predictObject, capturedImage: $capturedImage)
                        .edgesIgnoringSafeArea(.all)
                    if let predictObject = predictObject {
                        BoundingBoxView(predictObject: predictObject)
                    }
                }
//                NavigationLink(destination: ResultView()) {
//                    Text("点击这里进入下一页")
//                }
                VStack {
                    Spacer()
                    // 拍照按钮
                    Button(action: {
//NotificationCenter.default",允许APP中的不同部分传递消息，全局共享对象，用于广播消息
                        print("按下了拍照按钮")
                        NotificationCenter.default.post(name: .takePhoto, object: nil)
                        
                    }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .shadow(radius: 10)
                    }
                    .padding(.bottom, 30)
                }
            }
//            .onChange:要求of的对象是可以比较是否相等的，即满足Equatable协议，即要能满足<对象> == <对象> 可以返回True或者False
            // 监听 capturedImage 的变化
//            .onChange(of: capturedImage) { newValue in
//                
//                isCameraActive = false
//            }
//            .sheet:用于在视图层次结构中弹出一个新的视图，以item的值为触发（要求item是个可选类型，即为xxx？），只要item的值不是nil就会被激活并显示
            .sheet(item: $capturedImage) { identifiableImage in
                VStack {
                    Image(uiImage: identifiableImage.image)
                        .resizable()
                        .scaledToFit()
                    Button("关闭") {
                        isCameraActive = true
                        capturedImage = nil
                    }
                }
            }
        }
    }
}

struct BoundingBoxView: View {
    // 假设你从 YOLO 模型中提取的 xywh 值（已转换为像素值）
    var predictObject: [PredictObject]
    
    var width: CGFloat = UIScreen.main.bounds.width
    var height: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        GeometryReader { geometry in
            
            ForEach(predictObject, id: \.Id) { objectItem in
                
                
                let w = CGFloat(objectItem.width) * width
                let h = CGFloat(objectItem.height) * height
                let x = CGFloat(objectItem.xCenter) * width
                let y = CGFloat(objectItem.yCenter) * height
            
    //        Text("width: \(width), height: \(height)")
                

                ZStack {
                    if(objectItem.classId != -1) {
                        Text("\(LabelList11[objectItem.classId])(\(LabelList11En[objectItem.classId])): \(String(format: "%.2f", objectItem.confidence))")
                            .position(x: x, y: y - h / 2)
                        
                        // 显示矩形框
                        Rectangle()
                            .stroke(Color.green, lineWidth: 2)  // 绿色边框
                            .frame(width: w, height: h)
                            .position(x: x, y: y)
                            
                    }


                    
                    // 可选 在矩形框中心添加标记
    //                Circle()
    //                    .fill(Color.blue)
    //                    .frame(width: 8, height: 8)
    //                    .position(x: x, y: y)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

// extension: 允许为现有类型添加新的功能，在这里，extension 用于为 Notification.Name 类型添加一个新的静态常量。
// Notification.Name是一个类型，用来表示 通知 的名称，允许不同部分的代码之前进行通讯
extension Notification.Name {
    static let takePhoto = Notification.Name("takePhoto")
}

let LabelList11 = [
    "狗",
    "狐狸",
    "牛",
    "山羊",
    "马",
    "猪",
    "羊",
    "鹿",
    "公牛",
    "骡",
    "羊驼"
]

let LabelList11En = [
    "Dog",
    "Fox",
    "Cattle",
    "Goat",
    "Horse",
    "Pig",
    "Sheep",
    "Deer",
    "Bull",
    "Mule",
    "Alpaca"
]

let LabelList3 = [
      "人",
      "自行车",
      "汽车",
      "摩托车",
      "飞机",
      "巴士",
      "火车",
      "卡车",
      "船",
      "交通灯",
      "消防栓",
      "停车标志",
      "停车计时器",
      "长凳",
      "鸟",
      "猫",
      "狗",
      "马",
      "羊",
      "牛",
      "大象",
      "熊",
      "斑马",
      "长颈鹿",
      "背包",
      "雨伞",
      "手提包",
      "领带",
      "手提箱",
      "飞盘",
      "滑雪板",
      "滑雪板",
      "运动球",
      "风筝",
      "棒球棒",
      "棒球手套",
      "滑板",
      "冲浪板",
      "网球拍",
      "瓶子",
      "酒杯",
      "杯子",
      "叉子",
      "刀",
      "勺子",
      "碗",
      "香蕉",
      "苹果",
      "三明治",
      "橙色",
      "西兰花",
      "胡萝卜",
      "热狗",
      "披萨",
      "甜甜圈",
      "蛋糕",
      "椅子",
      "沙发",
      "盆栽植物",
      "床",
      "餐桌",
      "厕所",
      "电视",
      "笔记本电脑",
      "鼠标",
      "远程",
      "键盘",
      "手机",
      "微波炉",
      "烤箱",
      "烤面包机",
      "水槽",
      "冰箱",
      "书",
      "时钟",
      "花瓶",
      "剪刀",
      "泰迪熊",
      "吹风机",
      "牙刷",
    
]

#Preview {
    ContentView()
}
