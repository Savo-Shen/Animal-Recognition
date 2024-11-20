//
//  ResultView.swift
//  Animal_Recognition
//
//  Created by 沈逸帆 on 2024/11/17.
//

import SwiftUI

struct ResultView: View {
    var body: some View {
        VStack {
            Text("已获取的图片结果")
                .font(.headline)
                .fontWeight(.medium)
        }
        VStack {
            Text("list")
            ResultDetailView()
        }
        Spacer()
    }
}

struct ResultDetailView: View {
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Spacer()
            VStack {
                Text("动物名")
                Text("习性")
                Text("简介")
            }
            Spacer()
        }
    }
}

#Preview {
    ResultView()
}
