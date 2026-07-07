@Component
export struct ProfileMenuItem {
  @Prop iconIndex: number = 0
  @Prop label: string = ''
  @Prop hasToggle: boolean = false
  @Prop toggleValue: boolean = false
  @Prop showVersion: boolean = false

  onItemAction: () => void = (): void => {}
  onToggleChange: (value: boolean) => void =
    (value: boolean): void => {}

  @Builder IconBuilder() {
    if (this.iconIndex === 0) {
      Image($r('app.media.profile_preference'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    } else if (this.iconIndex === 1) {
      Image($r('app.media.profile_favorite'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    } else if (this.iconIndex === 2) {
      Image($r('app.media.profile_history'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    } else if (this.iconIndex === 3) {
      Image($r('app.media.profile_moon'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    } else if (this.iconIndex === 4) {
      Image($r('app.media.profile_bell'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    } else {
      Image($r('app.media.profile_info'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
    }
  }

  build() {
    Row() {
      Column() {
        this.IconBuilder()
      }
      .width(36)
      .height(36)
      .borderRadius(11)
      .backgroundColor('#F2F4FF')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(this.label)
        .fontSize(15)
        .fontColor('#1C1C1E')
        .margin({ left: 12 })

      Blank()

      if (this.hasToggle) {
        Toggle({
          type: ToggleType.Switch,
          isOn: this.toggleValue
        })
          .onChange((value: boolean) => {
            this.onToggleChange(value)
          })
      } else if (this.showVersion) {
        Text('v1.0.0')
          .fontSize(13)
          .fontColor('#B4B7BF')
          .margin({ right: 8 })
      } else {
        Image($r('app.media.icon_chevron_right'))
          .width(16)
          .height(16)
          .objectFit(ImageFit.Contain)
      }
    }
    .width('100%')
    .height(58)
    .padding({
      left: 14,
      right: 14
    })
    .backgroundColor(Color.White)
    .onClick(() => {
      if (!this.hasToggle) {
        this.onItemAction()
      }
    })
  }
}
