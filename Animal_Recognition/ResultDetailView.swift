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
        ScrollView {
            VStack {
                Image(uiImage: object.image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(270))
                    .frame(maxHeight: 300)
                Text("\(LabelList11[object.predictObject.classId])(\(LabelList11En[object.predictObject.classId]))")
                    .font(.title)
                    .padding()
                Text("准确度（Accuracy) ：\(object.predictObject.confidence)")
                Text(animals[object.predictObject.classId])
                    .padding()
                Text(animalsEn[object.predictObject.classId])
                    .padding()
                VStack {
                    Link("查看百科介绍", destination: URL(string: links[object.predictObject.classId])!)
                    Link("View the encyclopedia introduction", destination: URL(string: links[object.predictObject.classId])!)
                }
                    .font(.body)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("详情")
            .padding()
        }
    }
}

let links = [
    "https://baike.baidu.com/item/狗/85474",
    "https://baike.baidu.com/item/狐属/3494982",
    "https://baike.baidu.com/item/牛族/8182752",
    "https://baike.baidu.com/item/山羊/620683",
    "https://baike.baidu.com/item/马/7204564",
    "https://baike.baidu.com/item/猪/147315",
    "https://baike.baidu.com/item/羊/1947",
    "https://baike.baidu.com/item/鹿科/2253869",
    "https://baike.baidu.com/item/公牛/24357079",
    "https://baike.baidu.com/item/骡/63463",
    "https://baike.baidu.com/item/羊驼/802367"
]

let animals: [String] = [
    "狗：人类最忠诚的朋友，具有良好的嗅觉和听觉，广泛用于看家、搜救与陪伴。",
    "狐狸：聪明灵活，行动敏捷，常出现在民间故事中象征智慧和狡猾。",
    "牛：性情温顺，主要用于农耕和乳品生产，是重要的家畜之一。",
    "山羊：适应性强，喜欢在山地活动，能提供羊奶、羊毛和羊肉。",
    "马：速度快、耐力强，古代用于交通、农业与战争，也是体育项目中的重要动物。",
    "猪：体型健壮，繁殖力强，是人类主要的肉类来源之一。",
    "羊：温顺群居，以毛、肉、奶为主要利用，广泛分布于全球各地。",
    "鹿：外形优雅，雄性有角，生活在森林与草原，是野生与人工饲养并存的动物。",
    "公牛：未阉割的雄性牛，性格较为暴躁，象征力量和勇气。",
    "骡：马和驴的杂交品种，体力强、耐力好，但一般无法繁殖。",
    "羊驼：南美特有动物，性格温和，以其柔软且高质量的毛闻名。"
]
let animalsEn: [String] = [
    "Dog: The most loyal friend of humans, with excellent sense of smell and hearing. Commonly used for guarding homes, search and rescue, and companionship.",
    "Fox: Clever and agile, often symbolizes wisdom and cunning in folklore.",
    "Cattle: Gentle in temperament, mainly used for farming and dairy production. One of the most important domesticated animals.",
    "Goat: Highly adaptable and prefers mountainous areas. Provides milk, wool, and meat.",
    "Horse: Fast and enduring, historically used in transportation, agriculture, and warfare. Also important in sports.",
    "Pig: Robust and highly reproductive. One of the main sources of meat for humans.",
    "Sheep: Gentle and social animals. Valued for their wool, meat, and milk. Widely distributed across the world.",
    "Deer: Elegant in appearance. Males have antlers and live in forests and grasslands. Found both in the wild and in captivity.",
    "Bull: Uncastrated male cattle, usually more aggressive. Symbolizes strength and courage.",
    "Mule: A hybrid of a horse and a donkey. Strong and enduring but typically infertile.",
    "Alpaca: Native to South America, gentle in nature, and known for its soft and high-quality fleece."
]

