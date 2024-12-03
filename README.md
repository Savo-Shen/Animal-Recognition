# Animal-Recognition
An Initial iOS project developed by Swift and SwiftUI to recognize animals.

## 模型导出
``` python
model.export(format="coreml", int8=True, nms=True, imgsz=[640, 384])
```
其中只有设置nms为True之后，输出的才会是带格式的，否则知识数组
