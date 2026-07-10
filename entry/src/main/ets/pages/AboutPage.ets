import { NavRouter } from '../utils/NavRouter'

@Entry
@Component
struct AboutPage {
  @Builder FeatureIcon(index: number) {
    if (index === 0) {
      Image($r('app.media.icon_search'))
        .width(21)
        .height(21)
        .objectFit(ImageFit.Contain)
    } else if (index === 1) {
      Image($r('app.media.profile_history'))
        .width(21)
        .height(21)
        .objectFit(ImageFit.Contain)
    } else if (index === 2) {
      Image($r('app.media.profile_preference'))
        .width(21)
        .height(21)
        .objectFit(ImageFit.Contain)
    } else if (index === 3) {
      Image($r('app.media.profile_favorite'))
        .width(21)
        .height(21)
        .objectFit(ImageFit.Contain)
    } else if (index === 4) {
      Image($r('app.media.profile_avatar'))
        .width(21)
        .height(21)
        .objectFit(ImageFit.Contain)
    } else {
      Image($r('app.media.filter_tune'))
        .width(21)
        .height(21)
        .objectFit(ImageFit.Contain)
    }
  }

  @Builder FeatureItem(
    index: number,
    title: string,
    desc: string
  ) {
    Row() {
      Column() {
        this.FeatureIcon(index)
      }
      .width(42)
      .height(42)
      .borderRadius(13)
      .backgroundColor('#EEF1FF')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1C1E')

        Text(desc)
          .fontSize(12)
          .fontColor('#8E8E93')
          .lineHeight(18)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 13 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder SectionHeader(title: string) {
    Text(title)
      .fontSize(17)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1C1C1E')
      .width('100%')
      .margin({ bottom: 12 })
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.icon_back'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            NavRouter.back()
          })

        Text('关于我们')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({ left: 12 })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 10 }) {
            Column() {
              Image($r('app.media.icon_product_placeholder'))
                .width(52)
                .height(52)
                .objectFit(ImageFit.Contain)
            }
            .width(82)
            .height(82)
            .borderRadius(24)
            .backgroundColor('#EEF1FF')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text('ShopCompare')
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')
              .margin({ top: 4 })

            Text('v1.0.0')
              .fontSize(13)
              .fontColor('#8E8E93')
              .padding({
                left: 12,
                right: 12,
                top: 5,
                bottom: 5
              })
              .backgroundColor('#F5F6F8')
              .borderRadius(10)
          }
          .width('100%')
          .padding({ top: 28, bottom: 28 })
          .backgroundColor(Color.White)
          .borderRadius(18)
          .border({ width: 1, color: '#ECEEF2' })
          .alignItems(HorizontalAlign.Center)

          Column() {
            this.SectionHeader('产品简介')

            Text('ShopCompare 是一款跨平台商品比价工具，帮助你在京东、天猫、拼多多、抖音电商等多个平台中快速找到最低价商品。我们利用智能推荐算法，根据你的购物偏好为你推荐最合适的商品。')
              .fontSize(14)
              .fontColor('#3C3C3C')
              .lineHeight(23)
              .width('100%')
          }
          .width('100%')
          .padding(18)
          .backgroundColor(Color.White)
          .borderRadius(18)
          .border({ width: 1, color: '#ECEEF2' })

          Column() {
            this.SectionHeader('核心功能')

            this.FeatureItem(0, '跨平台比价', '实时展示多个电商平台的商品价格对比')
            Divider()
              .strokeWidth(0.5)
              .color('#ECEEF2')
              .margin({ left: 55 })

            this.FeatureItem(1, '价格走势', '追踪商品历史价格，掌握最佳购买时机')
            Divider()
              .strokeWidth(0.5)
              .color('#ECEEF2')
              .margin({ left: 55 })

            this.FeatureItem(2, '智能推荐', '基于你的购物偏好，推荐最合适的商品')
            Divider()
              .strokeWidth(0.5)
              .color('#ECEEF2')
              .margin({ left: 55 })

            this.FeatureItem(3, '收藏关注', '收藏心仪商品，降价时及时提醒')
            Divider()
              .strokeWidth(0.5)
              .color('#ECEEF2')
              .margin({ left: 55 })

            this.FeatureItem(4, '多维画像', '六维综合评价模型，全面了解商品')
            Divider()
              .strokeWidth(0.5)
              .color('#ECEEF2')
              .margin({ left: 55 })

            this.FeatureItem(5, '筛选比价', '按品牌、价格区间精准筛选，一键找到最低价')
          }
          .width('100%')
          .padding({
            left: 18,
            right: 18,
            top: 18,
            bottom: 6
          })
          .backgroundColor(Color.White)
          .borderRadius(18)
          .border({ width: 1, color: '#ECEEF2' })

          Column() {
            this.SectionHeader('技术栈')

            Text('前端：HarmonyOS ArkTS + ArkUI\n后端：Python FastAPI / Node.js\n数据库：PostgreSQL + Redis\n推荐引擎：协同过滤 + 冷启动混合策略')
              .fontSize(13)
              .fontColor('#3C3C3C')
              .lineHeight(23)
              .width('100%')
          }
          .width('100%')
          .padding(18)
          .backgroundColor(Color.White)
          .borderRadius(18)
          .border({ width: 1, color: '#ECEEF2' })

          Column() {
            this.SectionHeader('联系方式')

            Text('如有问题或建议，欢迎通过以下方式联系我们：\n\n📧 邮箱：support@shopcompare.com\n🌐 官网：https://shopcompare.com')
              .fontSize(13)
              .fontColor('#3C3C3C')
              .lineHeight(23)
              .width('100%')
          }
          .width('100%')
          .padding(18)
          .backgroundColor(Color.White)
          .borderRadius(18)
          .border({ width: 1, color: '#ECEEF2' })

          Text('Copyright ' + '\u00A9' + ' 2026 ShopCompare Team')
            .fontSize(12)
            .fontColor('#8E8E93')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 8, bottom: 26 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
