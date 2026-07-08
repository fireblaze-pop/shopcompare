@Component
export struct FilterOptionChip {
  @Prop label: string = ''
  @Prop selected: boolean = false

  onOptionAction: () => void = (): void => {}

  build() {
    Text(this.label)
      .fontSize(13)
      .fontWeight(
        this.selected ?
        FontWeight.Medium :
        FontWeight.Normal
      )
      .fontColor(
        this.selected ?
        Color.White :
        '#4C4F56'
      )
      .padding({
        left: 15,
        right: 15,
        top: 8,
        bottom: 8
      })
      .backgroundColor(
        this.selected ?
        '#5267E8' :
        '#F7F8FA'
      )
      .border({
        width: 1,
        color:
          this.selected ?
          '#5267E8' :
          '#E8EAF0'
      })
      .borderRadius(17)
      .onClick(() => {
        this.onOptionAction()
      })
  }
}
