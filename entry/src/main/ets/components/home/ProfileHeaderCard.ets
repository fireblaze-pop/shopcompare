@Component
export struct ProfileHeaderCard {
  @Prop compareCount: number = 0
  @Prop favoriteCount: number = 0

  build() {
    Row() {
      Column() {
        Image($r('app.media.profile_avatar'))
          .width(34)
          .height(34)
          .objectFit(ImageFit.Contain)
      }
      .width(64)
      .height(64)
      .borderRadius(20)
      .backgroundColor('#EEF1FF')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 5 }) {
        Text('购物达人')
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Text('让每一次比价都更聪明')
          .fontSize(13)
          .fontColor('#8E8E93')

        Row({ space: 16 }) {
          Text('已比价 ' + this.compareCount.toString() + ' 款')
            .fontSize(12)
            .fontColor('#5267E8')

          Text('收藏 ' + this.favoriteCount.toString() + ' 件')
            .fontSize(12)
            .fontColor('#5267E8')
        }
        .margin({ top: 3 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })
    }
    .width('100%')
    .padding({
      left: 18,
      right: 18,
      top: 20,
      bottom: 20
    })
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF3'
    })
  }
}
