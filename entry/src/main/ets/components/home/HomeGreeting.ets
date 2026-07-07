@Component
export struct HomeGreeting {
  @State greetingHeight: number = 64
  @State greetingOpacity: number = 1
  @State greetingBottomMargin: number = 16

  private greetingTimer: number = -1

  aboutToAppear(): void {
    this.greetingHeight = 64
    this.greetingOpacity = 1
    this.greetingBottomMargin = 16

    this.greetingTimer = setTimeout(() => {
      animateTo({
        duration: 450,
        curve: Curve.EaseInOut
      }, () => {
        this.greetingHeight = 0
        this.greetingOpacity = 0
        this.greetingBottomMargin = 0
      })
    }, 1800)
  }

  aboutToDisappear(): void {
    if (this.greetingTimer !== -1) {
      clearTimeout(this.greetingTimer)
      this.greetingTimer = -1
    }
  }

  build() {
    Column({ space: 6 }) {
      Text('你好，购物达人 👋')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')

      Text('今天想比什么？')
        .fontSize(14)
        .fontColor('#8E8E93')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height(this.greetingHeight)
    .opacity(this.greetingOpacity)
    .margin({
      top: 20,
      bottom: this.greetingBottomMargin
    })
    .clip(true)
  }
}
