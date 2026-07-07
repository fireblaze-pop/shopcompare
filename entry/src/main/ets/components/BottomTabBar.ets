interface TabItem {
  label: string
  icon: string
}

@Component
export struct BottomTabBar {
  @Prop currentTab: number = 0
  onTabChange: (index: number) => void = (index: number) => {}

  private tabs: TabItem[] = [
    { label: '\u9996\u9875', icon: '\uD83C\uDFE0' },
    { label: '\u53D1\u73B0', icon: '\uD83D\uDD0D' },
    { label: '\u6536\u85CF', icon: '\u2764\uFE0F' },
    { label: '\u6211\u7684', icon: '\uD83D\uDC64' }
  ]

  build() {
    Row() {
      ForEach(this.tabs, (item: TabItem, index: number) => {
        Column() {
          Text(item.icon)
            .fontSize(22)

          Text(item.label)
            .fontSize(10)
            .fontColor(index === this.currentTab ? '#007AFF' : '#8E8E93')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.onTabChange(index)
        })
      }, (item: TabItem, index: number) => item.label)
    }
    .width('100%')
    .height(56)
    .padding({ bottom: 28 })
    .backgroundColor('rgba(255,255,255,0.85)')
    .backdropBlur(20)
    .alignItems(VerticalAlign.Center)
  }
}
