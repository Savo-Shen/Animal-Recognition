//
//  ResultDetailView.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2025/4/6.
//
import SwiftUI


struct ObjectDetailView: View {
    var object: GotObject

    var body: some View {
        VStack {
            Image(uiImage: object.image)
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(270))
            Text("动物名：\(LabelList11[object.predictObject.classId])")
                .font(.title)
                .padding()
            Text("习性：暂时未提供")
                .padding(.bottom)
            Text("简介：暂时未提供")
            Spacer()
        }
        .navigationTitle("详情")
        .padding()
    }
}
