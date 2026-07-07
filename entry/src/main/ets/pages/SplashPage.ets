import { router } from '@kit.ArkUI';

@Entry
@Component
struct SplashPage {
  @State opacityValue: number = 0;

  aboutToAppear(): void {
    setTimeout(() => {
      animateTo({ duration: 1000, curve: Curve.EaseInOut }, () => {
        this.opacityValue = 1;
      });
    }, 100);

    setTimeout(() => {
      router.replaceUrl({ url: 'pages/LoginPage' });
    }, 2000);
  }

  build() {
    Column() {
      Blank()
        .layoutWeight(1);

      Column() {
        Text('📦')
          .fontSize(72);

        Text('ShopCompare')
          .fontSize(36)
          .fontWeight(700)
          .fontColor(Color.White)
          .margin({ top: 16 });

        Text('跨平台比价 · 聪明消费')
          .fontSize(16)
          .fontColor(Color.White)
          .opacity(0.8)
          .margin({ top: 8 });
      }
      .alignItems(HorizontalAlign.Center)
      .opacity(this.opacityValue);

      Blank()
        .layoutWeight(1);

      Blank()
        .layoutWeight(1)

      Row() {
        Button('跳过')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('rgba(255,255,255,0.2)')
          .borderRadius(20)
          .padding({ left: 24, right: 24, top: 10, bottom: 10 })
          .onClick(() => {
            router.replaceUrl({ url: 'pages/LoginPage' })
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })

      Text('Powered by HarmonyOS')
        .fontSize(12)
        .fontColor(Color.White)
        .opacity(0.5)
        .margin({ bottom: 40 });
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [['#007AFF', 0.0], ['#5856D6', 1.0]]
    });
  }
}
