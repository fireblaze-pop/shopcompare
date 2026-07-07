@Component
export struct SearchBar {
  @Prop placeholder: string = '\u641C\u7D22\u5546\u54C1\u3001\u54C1\u7C7B...'
  @Prop inputValue: string = ''
  onChange: (value: string) => void = (value: string) => {}
  onInputFocus: () => void = () => {}
  onInputBlur: () => void = () => {}
  onSearchClick: () => void = () => {}

  build() {
    Row() {
      Text('\uD83D\uDD0D')
        .fontSize(16)
        .margin({ left: 12 })

      TextInput({ text: this.inputValue, placeholder: this.placeholder })
        .fontSize(15)
        .fontColor('#1C1C1E')
        .placeholderColor('#8E8E93')
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .layoutWeight(1)
        .height(44)
        .padding({ left: 8, right: 8 })
        .enabled(false)
        .onChange((value: string) => {
          this.onChange(value)
        })

      if (this.inputValue.length > 0) {
        Text('\u2715')
          .fontSize(14)
          .fontColor('#8E8E93')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .borderRadius(14)
          .backgroundColor('#D1D1D6')
          .margin({ right: 8 })
          .onClick(() => {
            this.onChange('')
          })
      }
    }
    .width('100%')
    .height(44)
    .borderRadius(22)
    .backgroundColor('#F2F2F7')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onSearchClick()
    })
  }
}
