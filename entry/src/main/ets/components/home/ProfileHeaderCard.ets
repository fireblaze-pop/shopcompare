@Component
export struct ProfileHeaderCard {
  @Prop nickname: string = '购物达人'
  @Prop bio: string = '让每一次比价都更聪明'
  @Prop preferenceCount: number = 0
  @Prop favoriteCount: number = 0

  onEditAction: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        Column() {
          Image($r('app.media.profile_avatar'))
            .width(36)
            .height(36)
            .objectFit(ImageFit.Contain)
        }
        .width(66)
        .height(66)
        .borderRadius(21)
        .backgroundColor('#EEF1FF')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 6 }) {
          Row() {
            Text(this.nickname)
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({
                overflow: TextOverflow.Ellipsis
              })

            Text('编辑资料')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#5267E8')
              .padding({
                left: 10,
                right: 10,
                top: 6,
                bottom: 6
              })
              .backgroundColor('#EEF1FF')
              .borderRadius(10)
              .onClick(() => {
                this.onEditAction()
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.bio)
            .fontSize(13)
            .fontColor('#8E8E93')
            .maxLines(2)
            .textOverflow({
              overflow: TextOverflow.Ellipsis
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 15 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        Column({ space: 4 }) {
          Text(this.preferenceCount.toString())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text('关注品类')
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column()
          .width(1)
          .height(28)
          .backgroundColor('#ECEEF2')

        Column({ space: 4 }) {
          Text(this.favoriteCount.toString())
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text('收藏商品')
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 17 })
      .margin({ top: 17 })
      .border({
        width: { top: 0.5 },
        color: '#ECEEF2'
      })
    }
    .width('100%')
    .padding({
      left: 18,
      right: 18,
      top: 20,
      bottom: 18
    })
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({ width: 1, color: '#ECEEF2' })
  }
}
