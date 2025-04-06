//
//  ResultView.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/17.
//

import SwiftUI

struct ResultView: View {
    
    @Binding var gotObjectList: [GotObject]
    @State var zoomedImage: UIImage? = nil
    @State var isZoomed: Bool = false
    
    var body: some View {
        ZStack {
            if let image = zoomedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isZoomed ? UIScreen.main.bounds.width : 100, // 放大为全屏或设置为初始大小
                           height: isZoomed ? UIScreen.main.bounds.height : 100)
                    .cornerRadius(isZoomed ? 0 : 20) // 缩小时带圆角，放大时去掉圆角
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut(duration: 0.5), value: isZoomed) // 添加平滑动画
                    .onAppear() {
                        isZoomed = true
                    }
                    .onTapGesture {
                        isZoomed = false
                        zoomedImage = nil
                    }
                    .rotationEffect(.degrees(270))
            }
            else {
                VStack {
                    Text("已获取的图片结果")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                    ResultDetailView(gotObjectList: gotObjectList, isZoomed: $isZoomed, zoomedImage: $zoomedImage)
                    Spacer()
                }
            }
        }
    }
}

struct ResultDetailView: View {
    
    var gotObjectList: [GotObject]
    @Binding var isZoomed: Bool
    @Binding var zoomedImage: UIImage?
    
    var body: some View {
        List {
            ForEach(gotObjectList, id: \.Id) { object in
                HStack {
                    Image(uiImage: object.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20)) // 裁剪图片为圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 2)
                        )
//                        .animation(.easeInOut(duration: 0.3), value: isZoomed) // 添加平滑动画
                        .onTapGesture {
                            zoomedImage = object.image
                        }
                        .rotationEffect(.degrees(270))
                    Spacer()
                    VStack {
                        Text("动物名：\(LabelList11[object.predictObject.classId])")
                        Text("习性")
                        Text("简介")
                    }
                    Spacer()
                }
            }
        }
    }
}

//#Preview {
//    ResultView()
//}
