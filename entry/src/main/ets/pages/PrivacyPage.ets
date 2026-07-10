import { NavRouter } from '../utils/NavRouter'

@Entry
@Component
struct PrivacyPage {
  build() {
    Column() {
      Row() {
        Text('\u2190')
          .fontSize(24)
          .fontColor('#1C1C1E')
          .padding({ right: 12 })
          .onClick(() => {
            NavRouter.back()
          })
        Text('隐私政策')
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#1C1C1E')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 20 }) {
          Text('最后更新日期：2026年7月6日')
            .fontSize(13)
            .fontColor('#8E8E93')
            .width('100%')

          this.section('一、我们收集的信息', [
            '手机号码：用于用户注册和登录认证',
            '搜索记录：用于提供搜索历史功能',
            '浏览和收藏记录：用于个性化商品推荐',
            '设备信息：用于优化应用性能和用户体验'
          ])

          this.section('二、信息的使用方式', [
            '提供商品搜索、比价和推荐服务',
            '改进和优化我们的产品和服务',
            '向您发送降价提醒等通知（需您授权）',
            '我们不会将您的个人信息出售给第三方'
          ])

          this.section('三、信息的存储与保护', [
            '您的数据加密存储在本地设备和云端服务器',
            '我们采用业界标准的安全措施保护您的数据',
            '密码使用bcrypt算法加密存储，我们无法获取您的明文密码'
          ])

          this.section('四、您的权利', [
            '您可以在设置中查看和修改个人信息',
            '您可以随时删除搜索历史和收藏记录',
            '您可以选择退出登录来清除本地数据',
            '如需注销账号，请联系客服处理'
          ])

          this.section('五、第三方服务', [
            '本应用可能包含第三方电商平台的链接',
            '点击商品链接跳转至第三方平台时，适用该平台的隐私政策',
            '我们不对第三方平台的隐私保护措施负责'
          ])

          this.section('六、联系我们', [
            '如果您对本隐私政策有任何疑问，请通过以下方式联系我们：',
            '邮箱：support@shopcompare.com'
          ])
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 32 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  section(title: string, items: string[]) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .width('100%')

      ForEach(items, (item: string, index: number) => {
        Row() {
          Text((index + 1).toString() + '. ')
            .fontSize(14)
            .fontColor('#8E8E93')
          Text(item)
            .fontSize(14)
            .fontColor('#3C3C3C')
            .lineHeight(22)
            .layoutWeight(1)
        }
        .width('100%')
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
