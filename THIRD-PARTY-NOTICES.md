第三方组件许可声明（THIRD-PARTY NOTICES）
============================================

本作品「金刚经儿童精读融合版」为单文件离线 Web 应用，内嵌以下第三方
开源组件。这些组件按各自原始许可证保留，不受主许可证（CC BY-NC-SA 4.0）
的非商业性条款限制，可依据其原许可独立使用。

1. HanziWriter
   - 用途：汉字笔画顺序动画与描红渲染引擎（MIT License）
   - 许可文件：同目录 LICENSE-MIT-hanzi-writer.txt
   - 官方：https://github.com/chanind/hanzi-writer

2. 汉字笔画数据（hanzi-writer-data / CHAR_DATA）
   - 用途：提供各汉字的笔画路径（strokes）与中线（medians），
     用于生成金骨架描红效果。
   - 来源：源自 Arphic 开源字体（文鼎公开释出之 PL 字体）的笔画提取，
     以 Arphic Public License（ARPHICPL.TXT）发布。
   - 许可文件：同目录 ARPHICPL.TXT
   - 说明：本项目仅使用其笔画几何数据，未内嵌任何字体文件（.ttf/.woff），
     因而不涉及字体授权风险。

3. 字体引用说明
   - 描字面板与卡片使用的楷体（KaiTi / STKaiti / SimKai）为运行时
     引用用户系统已安装字体，非内嵌分发，零字体侵权风险。

--------------------------------------------
主许可证（CC BY-NC-SA 4.0，见 LICENSE 文件）仅覆盖作者原创内容：
  · 应用 HTML / JavaScript 逻辑
  · 儿童白话翻译、精读体系设计、四轮教学法
  · 界面、文案与视觉设计（含金骨架参数体系）

如第三方组件许可与本声明冲突，以各组件原许可文件为准。
