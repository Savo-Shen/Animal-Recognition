import SwiftUI

struct ImageCroppingExample: View {
    @State private var originalImage = UIImage(named: "test")! // 替换为实际图片
    @State private var croppedImage: UIImage? = nil

    var body: some View {
        VStack {
            // 显示原始图片
            Text("Original Image\(originalImage.cgImage?.height)")
                .font(.headline)
            HStack {
                Image(uiImage: originalImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .border(Color.gray, width: 2)
                    .padding()
                
                // 显示裁剪后的图片
                if let croppedImage = croppedImage {
                    Text("Cropped Image")
                        .font(.headline)
                    Image(uiImage: croppedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .border(Color.gray, width: 2)
                        .padding()
                }
            }

            Spacer()
            // 裁剪按钮
            Button("Crop Image") {
                let croppedRect = CGRect(x: 0, y: 0, width: 500, height: 2778) // 裁剪区域
                croppedImage = cropUIImage(originalImage, to: croppedRect)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }

    /// 裁剪 UIImage
    func cropUIImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage")
            return nil
        }

        // 确保裁剪区域合法
        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            print("Failed to crop image")
            return nil
        }

        // 转换回 UIImage
        return UIImage(cgImage: croppedCGImage)
    }
}

#Preview {
    ImageCroppingExample()
}
