@Component
export struct BottomTabItem {
  @Prop index: number = 0
  @Prop isSelected: boolean = false

  onTabClick: () => void = (): void => {}

  @Builder IconBuilder() {
    if (this.index === 0) {
      Image($r('app.media.tab_home'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
        .opacity(this.isSelected ? 1 : 0.38)
    } else if (this.index === 1) {
      Image($r('app.media.tab_discover'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
        .opacity(this.isSelected ? 1 : 0.38)
    } else if (this.index === 2) {
      Image($r('app.media.tab_favorite'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
        .opacity(this.isSelected ? 1 : 0.38)
    } else {
      Image($r('app.media.tab_profile'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)
        .opacity(this.isSelected ? 1 : 0.38)
    }
  }

  build() {
    Column({ space: 3 }) {
      this.IconBuilder()

      Text(this.getLabel())
        .fontSize(11)
        .fontColor(
          this.isSelected ?
          '#5267E8' :
          '#8E8E93'
        )
        .fontWeight(
          this.isSelected ?
          FontWeight.Medium :
          FontWeight.Normal
        )

      if (this.isSelected) {
        Column()
          .width(4)
          .height(4)
          .borderRadius(2)
          .backgroundColor('#5267E8')
      } else {
        Column()
          .width(4)
          .height(4)
      }
    }
    .width('100%')
    .padding({
      top: 8,
      bottom: 6
    })
    .backgroundColor(Color.White)
    .onClick(() => {
      this.onTabClick()
    })
  }

  private getLabel(): string {
    if (this.index === 0) {
      return '首页'
    }

    if (this.index === 1) {
      return '发现'
    }

    if (this.index === 2) {
      return '收藏'
    }

    return '我的'
  }
}
