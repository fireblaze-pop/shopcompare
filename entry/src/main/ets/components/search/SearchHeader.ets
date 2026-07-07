@Component
export struct SearchHeader {
  @Prop searchText: string = ''

  onBack: () => void = (): void => {}
  onTextChange: (value: string) => void =
    (value: string): void => {}
  onSubmit: () => void = (): void => {}
  onClear: () => void = (): void => {}
  onSearch: () => void = (): void => {}

  build() {
    Row({ space: 10 }) {
      Row() {
        Image($r('app.media.icon_back'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
      .width(40)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onBack()
      })

      Row() {
        Image($r('app.media.icon_search'))
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)
          .margin({
            left: 14
          })

        TextInput({
          placeholder: '搜商品、品牌或型号',
          text: this.searchText
        })
          .fontSize(14)
          .fontColor('#1C1C1E')
          .placeholderColor('#9A9DA4')
          .backgroundColor(Color.Transparent)
          .border({
            width: 0
          })
          .layoutWeight(1)
          .height(48)
          .padding({
            left: 9,
            right: 4
          })
          .onChange((value: string) => {
            this.onTextChange(value)
          })
          .onSubmit(() => {
            this.onSubmit()
          })

        if (this.searchText.length > 0) {
          Text('×')
            .fontSize(16)
            .fontColor('#73767D')
            .width(26)
            .height(26)
            .textAlign(TextAlign.Center)
            .borderRadius(13)
            .backgroundColor('#E9EBF0')
            .margin({
              right: 9
            })
            .onClick(() => {
              this.onClear()
            })
        }
      }
      .layoutWeight(1)
      .height(48)
      .borderRadius(16)
      .backgroundColor('#F7F8FA')
      .border({
        width: 1,
        color: '#E8EAF0'
      })
      .alignItems(VerticalAlign.Center)

      Button('搜索')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor('#5267E8')
        .width(64)
        .height(44)
        .borderRadius(14)
        .onClick(() => {
          this.onSearch()
        })
    }
    .width('100%')
    .height(72)
    .padding({
      left: 8,
      right: 14
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }
}
