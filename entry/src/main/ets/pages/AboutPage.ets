import { router } from '@kit.ArkUI'

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      Row() {
        Text('\u2190')
          .fontSize(24)
          .fontColor('#1C1C1E')
          .padding({ right: 12 })
          .onClick(() => {
            router.back()
          })
        Text('关于我们')
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#1C1C1E')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Column() {
        Scroll() {
          Column({ space: 20 }) {
            Column({ space: 12 }) {
              Text('📦')
                .fontSize(64)

              Text('ShopCompare')
                .fontSize(28)
                .fontWeight(700)
                .fontColor('#1C1C1E')

              Text('v1.0.0')
                .fontSize(14)
                .fontColor('#8E8E93')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 40, bottom: 20 })

            Column({ space: 12 }) {
              Text('产品简介')
                .fontSize(18)
                .fontWeight(600)
                .fontColor('#1C1C1E')
                .width('100%')

              Text('ShopCompare 是一款跨平台商品比价工具，帮助你在京东、天猫、拼多多、抖音电商等多个平台中快速找到最低价商品。我们利用智能推荐算法，根据你的购物偏好为你推荐最合适的商品。')
                .fontSize(14)
                .fontColor('#3C3C3C')
                .lineHeight(22)
                .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            Column({ space: 12 }) {
              Text('核心功能')
                .fontSize(18)
                .fontWeight(600)
                .fontColor('#1C1C1E')
                .width('100%')

              Column({ space: 12 }) {
                this.featureItem('🔍', '跨平台比价', '实时展示多个电商平台的商品价格对比')
                this.featureItem('📊', '价格走势', '追踪商品历史价格，掌握最佳购买时机')
                this.featureItem('🎯', '智能推荐', '基于你的购物偏好，推荐最合适的商品')
                this.featureItem('❤️', '收藏关注', '收藏心仪商品，降价时及时提醒')
                this.featureItem('📱', '多维画像', '六维综合评价模型，全面了解商品')
                this.featureItem('🏷️', '筛选比价', '按品牌、价格区间精准筛选，一键找到最低价')
              }
              .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            Column({ space: 12 }) {
              Text('技术栈')
                .fontSize(18)
                .fontWeight(600)
                .fontColor('#1C1C1E')
                .width('100%')

              Text('前端：HarmonyOS ArkTS + ArkUI\n后端：Python FastAPI / Node.js\n数据库：PostgreSQL + Redis\n推荐引擎：协同过滤 + 冷启动混合策略')
                .fontSize(13)
                .fontColor('#3C3C3C')
                .lineHeight(22)
                .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            Column({ space: 12 }) {
              Text('联系方式')
                .fontSize(18)
                .fontWeight(600)
                .fontColor('#1C1C1E')
                .width('100%')

              Text('如有问题或建议，欢迎通过以下方式联系我们：\n\n📧 邮箱：support@shopcompare.com\n🌐 官网：https://shopcompare.com')
                .fontSize(13)
                .fontColor('#3C3C3C')
                .lineHeight(22)
                .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F2F2F7')
        .scrollBar(BarState.Off)

        Row() {
          Text('Copyright ' + '\u00A9' + ' 2026 ShopCompare Team')
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .height(44)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  featureItem(icon: string, title: string, desc: string) {
    Row() {
      Text(icon)
        .fontSize(24)

      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(500)
          .fontColor('#1C1C1E')

        Text(desc)
          .fontSize(12)
          .fontColor('#8E8E93')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
      .layoutWeight(1)
    }
    .width('100%')
  }
}
