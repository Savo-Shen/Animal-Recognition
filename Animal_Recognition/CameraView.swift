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

//Hashable才满足hash
struct GotObject: Identifiable, Hashable {
    let Id: UUID = UUID() // 唯一标识符
    var predictObject: PredictObject
    var image: UIImage

    // 确保 `GotObject` 类型遵循 `Identifiable` 协议
    var id: UUID { self.Id } // `Identifiable` 协议要求实现 `id` 属性
    
    // 确保 `GotObject` 类型遵循 `Hashable`
    static func ==(lhs: GotObject, rhs: GotObject) -> Bool {
        return lhs.Id == rhs.Id // 比较 `Id`
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(Id) // 使用 `Id` 来计算哈希
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
    @State private var isFlashing: Bool = false
    @State var gotObjectList: [GotObject] = []
    
    var body: some View {
//      NavigationView: 是旧版，在iOS16后被NavigationStack取代了
        NavigationStack {
            ZStack {
                if isCameraActive {

//                    ResultView(gotObjectList: gotObjectList)
                        CameraView(predictObject: $predictObject, capturedImage: $capturedImage, isFlashing: $isFlashing, gotObjectList: $gotObjectList)
                            .edgesIgnoringSafeArea(.all)

                    if let predictObject = predictObject {
                        BoundingBoxView(predictObject: predictObject, isFlashing: isFlashing)
                    }
                    
                    SlideInOutAnimationView(isFlashing: isFlashing)
                    
                }
                ZStack {
                    // 自定义带内外圆角的背景
                    RoundedRectangle(cornerRadius: 25) // 圆角矩形
                        .fill(Color.black.opacity(0.6)) // 半透明黑色背景
                        .frame(width: 240, height: 50) // 控制尺寸
                    // 文字
                    Text("Welcome use this app")
                        .foregroundColor(.white) // 文字颜色
                        .font(.headline)
                }
                .rotationEffect(.degrees(90)) // 旋转 90°，让它和背景匹配
                .position(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height / 2) // 让它贴近屏幕右侧
                .edgesIgnoringSafeArea(.all) // 确保背景不受安全区域影响
                
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: ResultView(gotObjectList: $gotObjectList)
                            .onAppear {
                                isCameraActive = false
        //                        print("no")
                            }
                            .onDisappear {
                                // 在返回时恢复初始状态
                                isCameraActive = true
        //                        print("hello")
                            }
                        ) {
                            Image("FavoritesIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .padding()
                                .rotationEffect(.degrees(90))
                        }
                        .padding(.trailing, 20)
                    }
                }
                
               
                VStack {
                    Spacer()
                    // 拍照按钮
                    Button(action: {
//NotificationCenter.default",允许APP中的不同部分传递消息，全局共享对象，用于广播消息
//                        print("按下了拍照按钮")
                        if(self.predictObject?[0].classId != -1) {
                            self.isFlashing = true
                            NotificationCenter.default.post(name: .takePhoto, object: nil)
                        }
                        
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
    var isFlashing: Bool = false
    
    var width: CGFloat = UIScreen.main.bounds.width
    var height: CGFloat = UIScreen.main.bounds.height
    
    @State var isShowFlashing: Bool = false
    
    var body: some View {
            
        let folderPosition = CGPoint(x: (width / 2) + 140, y: (height / 2) + 120)
            
            ForEach(predictObject, id: \.Id) { objectItem in
                
                let w = CGFloat(objectItem.width) * width
                let h = CGFloat(objectItem.height) * height
                // 因为整体转过来了，所以手动把h和w转过来
//                let h = CGFloat(objectItem.width) * width
//                let w = CGFloat(objectItem.height) * height
                let x = CGFloat(objectItem.xCenter) * width
                let y = CGFloat(objectItem.yCenter) * height - 90
                
            
    //        Text("width: \(width), height: \(height)")
                
                if(objectItem.classId != -1) {
                    ZStack {
                        GeometryReader { geometry in

//                            HStack {
//                                Text("\(LabelList11[objectItem.classId])(\(LabelList11En[objectItem.classId])): \(String(format: "%.2f", objectItem.confidence))")
////                                Text("\(LabelList3[objectItem.classId]): \(String(format: "%.2f", objectItem.confidence))")
//                                //                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // 左上角对齐
//                                    .foregroundColor(.black)
//                                    .font(.title)
//                                Spacer()
//                            }
//                            .background(Color.gray.opacity(0.5))
//                            .rotationEffect(.degrees(90))
//                            .offset(x: -(w / 2) - 16, y: 0)
//                            .position(x: x, y: y)
                            HStack {
                                Text("\(LabelList11[objectItem.classId])(\(LabelList11En[objectItem.classId])): \(String(format: "%.2f", objectItem.confidence))")
                                    .foregroundColor(.black)
                                    .font(.system(size: min(max(h * 0.2, 12), 24))) // 限制字体大小范围
//                                    .frame(width: w, height: h, alignment: .center) // 让 Text 的尺寸匹配 w 和 h
                                    .minimumScaleFactor(0.5) // 允许字体缩小但不至于太小
                                    .lineLimit(1) // 限制为单行，避免背景过大
                                    .padding(4) // 增加一点间距，使背景稍微大于文字
                                    .background(Color.gray.opacity(0.5)) // 仅包裹文字的背景
                                    .cornerRadius(5) // 让背景圆角化，使其美观

                            }
                            .rotationEffect(.degrees(90)) // 旋转文本以匹配 UI
                            .offset(x: (w / 2) + 16, y: 0)
                            .position(x: x, y: y)
                            
                            //                        .position(x: x, y: y)
                            //                            .background(Color.gray.opacity(0.5))
                            //                            .background(.thinMaterial)
                            
                            //                            Spacer()
                            // 显示矩形框
                            //                            Rectangle()
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 2)
                                .frame(width: w, height: h)
                                .position(x: x, y: y)
                            //                                .position(x: x, y: y)
                            // 闪烁效果的白色覆盖层
                            if isFlashing {
                                Color.white
//                                    .opacity(isShowFlashing ? 0.1 : 0.7) // 初始透明度
                                //                                .transition(.opacity)
                                    .scaleEffect(isShowFlashing ? 0 : 1.0)
//                                    .position(isShowFlashing ? folderPosition : CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                                    .position(isShowFlashing ? folderPosition : CGPoint(x: x, y: y))
                                    .frame(width: w, height: h)
                                    .animation(.easeOut(duration: 0.5), value: isShowFlashing)
                                
                                    .onAppear {
                                        isShowFlashing = true
                                    }
                                    .onDisappear() {
                                        isShowFlashing = false
                                    }
                            }
                            
                            
                            // 可选 在矩形框中心添加标记
                            //                Circle()
                            //                    .fill(Color.blue)
                            //                    .frame(width: 8, height: 8)
                            //                    .position(x: x, y: y)
                            //                        .frame(width: w, height: h)
                            
                        }
                    }
                    

                    

//                    .frame(width: width, height: height)
    //                .animation(.spring, value: 0.0)
            }
        }
    }
}

struct SlideInOutAnimationView: View {
    var isFlashing: Bool = false
    @State private var animationTrigger: Bool = false // 内部动画控制变量

    var body: some View {
        ZStack {
            Image("FavoritesIcon")
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(90))
                .frame(width: 100, height: 100)
                .offset(x: isFlashing ? 140 : UIScreen.main.bounds.width, y: 180) // 控制图片位置
                .animation(.easeInOut(duration: 0.5), value: isFlashing)
                .onChange(of: isFlashing) {
                    startAnimation() // 触发动画
                }

        }
    }
    /// 自动触发动画
    private func startAnimation() {
        animationTrigger = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 动画时长
            animationTrigger = false
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
