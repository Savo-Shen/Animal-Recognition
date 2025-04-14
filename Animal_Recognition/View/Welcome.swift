import SwiftUI

struct Welcome: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景图
                Image("welcome background")
                    .resizable()
                    .scaledToFill()
                    .offset(x: -130, y: -30)
                    .ignoresSafeArea()
                // 半透明遮罩
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("欢迎来到动物识别 App")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 40)
                    Text("Welcome to Animal Recognition App")
                        .foregroundColor(.white)
                        .padding(.bottom, 50)
                        .padding(.top, -10)
                    Text("识别自然界中的奇妙动物，\n只需要将手机横过来对着它。")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Text("Discover the wonders of animals in nature,\n just turn your phone sideways \nand aim it at the animal — it’s that easy!")
                        .foregroundColor(.white)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    Spacer()

                    VStack(spacing: 12) {
                        // 漂亮的按钮
                        NavigationLink(destination: ContentView()) {
                            Text("🚀 开始识别")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(colors: [Color.blue, Color.purple],
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                                )
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 4)
                        }
                        .padding(.horizontal, 50)

                        // 用户提示
                        Text("👉 请将手机横屏以获得最佳体验\n👉 Please rotate your phone horizontally for the best experience")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 80)
                }
            }
        }
    }
}

#Preview {
    Welcome()
}

