@Component
export struct SearchBar {
  @Prop placeholder: string = '搜商品、品牌或型号'
  @Prop inputValue: string = ''

  onChange: (value: string) => void = (value: string): void => {}
  onInputFocus: () => void = (): void => {}
  onInputBlur: () => void = (): void => {}
  onSearchClick: () => void = (): void => {}

  build() {
    Row() {
      Row({ space: 8 }) {
        Image($r('app.media.icon_search'))
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)

        Text(this.inputValue.length > 0 ? this.inputValue : this.placeholder)
          .fontSize(14)
          .fontColor(this.inputValue.length > 0 ? '#1C1C1E' : '#9A9AA1')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .height('100%')
      .padding({ left: 14, right: 10 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onSearchClick()
      })

      Button('搜索')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor('#5267E8')
        .width(70)
        .height(40)
        .borderRadius(12)
        .margin({ right: 4 })
        .onClick(() => {
          this.onSearchClick()
        })
    }
    .width('100%')
    .height(50)
    .backgroundColor(Color.White)
    .border({
      width: 1.5,
      color: '#5267E8'
    })
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
  }
}
