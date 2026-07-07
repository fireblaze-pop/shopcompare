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
      // 左侧搜索入口
      Row({ space: 8 }) {
        Text('⌕')
          .fontSize(22)
          .fontColor('#7C7C84')

        Text(this.inputValue.length > 0 ? this.inputValue : this.placeholder)
          .fontSize(14)
          .fontColor(this.inputValue.length > 0 ? '#1C1C1E' : '#9A9AA1')
          .maxLines(1)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
      }
      .layoutWeight(1)
      .height('100%')
      .padding({
        left: 14,
        right: 10
      })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.onSearchClick()
      })

      // 右侧搜索按钮
      Button('搜索')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor('#5267E8')
        .width(70)
        .height(40)
        .borderRadius(12)
        .margin({
          right: 4
        })
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
