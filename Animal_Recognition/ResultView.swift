//
//  ResultView.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/17.
//

import SwiftUI

struct FullScreenZoomedImage: View {
    var image: UIImage
    var onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // 设置背景为白色

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                            .onEnded { finalValue in
                                withAnimation {
                                    scale = max(1.0, finalValue)
                                }
                            },
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                // 拖动结束后恢复偏移
                                withAnimation(.spring()) {
                                    offset = .zero
                                }
                                lastOffset = .zero
                            }
                    )
                )
                .onTapGesture {
                    onDismiss()
                }
                .rotationEffect(.degrees(270))
        }
    }
}

struct ResultView: View {
    
    @Binding var gotObjectList: [GotObject]
    @State var zoomedImage: UIImage? = nil
    
    var body: some View {
        VStack {
            Text("已获取的图片结果")
                .font(.largeTitle)
                .fontWeight(.medium)
            ResultDetailView(gotObjectList: gotObjectList, zoomedImage: $zoomedImage)
            Spacer()
        }
        .sheet(item: $zoomedImage) { image in
            FullScreenZoomedImage(image: image) {
                zoomedImage = nil
            }
        }

    }
}

struct ResultDetailView: View {
    
    var gotObjectList: [GotObject]
    @Binding var zoomedImage: UIImage?
    
    @State private var selectedItem: GotObject? = nil // 新增状态来记录当前被选中的物品
    
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
                        .rotationEffect(.degrees(270))
                        .onTapGesture {
                            zoomedImage = object.image
                        }
                    Spacer()
                    NavigationLink(
                        destination: ObjectDetailView(object: object),
                        tag: object,
                        selection: $selectedItem
                    ) {
                        VStack(alignment: .leading) {
                            Text("动物名：\(LabelList11[object.predictObject.classId])")
                            Text("习性")
                            Text("简介")
                        }
                    }
//                    NavigationLink(
//                        value: object,
//                        label: {
//                            VStack(alignment: .leading) {
//                                Text("动物名：\(LabelList11[object.predictObject.classId])")
//                                Text("习性")
//                                Text("简介")
//                            }
//                        }
//                    )
//                    .navigationDestination(for: GotObject.self) { object in
//                        ObjectDetailView(object: object) // 导航到详情页
//                    }
                    Spacer()
                }
            }
        }
    }
}

extension UIImage: Identifiable {
    public var id: String { "\(self.hash)" }
}

//#Preview {
//    ResultView()
//}
