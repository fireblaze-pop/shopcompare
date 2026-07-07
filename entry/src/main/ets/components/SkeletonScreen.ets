@Component
export struct SkeletonScreen {
  @Prop skeletonType: string = 'card'
  @Prop count: number = 3
  @State private shimmerOpacity: number = 0.3
  private timerId: number = -1

  aboutToAppear(): void {
    let self: SkeletonScreen = this
    this.timerId = setInterval(() => {
      if (self.shimmerOpacity > 0.4) {
        self.shimmerOpacity = 0.3
      } else {
        self.shimmerOpacity = 0.6
      }
    }, 800)
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  build() {
    Column() {
      if (this.skeletonType === 'card') {
        ForEach(this.buildCountArray(), (item: number) => {
          Column() {
            Row()
              .width('100%')
              .height(160)
              .backgroundColor('#E5E5EA')
              .borderRadius({ topLeft: 16, topRight: 16 })
              .opacity(this.shimmerOpacity)
              .animation({ duration: 750, curve: Curve.EaseInOut })

            Column() {
              Row()
                .width('75%')
                .height(14)
                .backgroundColor('#E5E5EA')
                .borderRadius(4)
                .opacity(this.shimmerOpacity)
                .animation({ duration: 750, curve: Curve.EaseInOut })

              Row()
                .width('90%')
                .height(14)
                .backgroundColor('#E5E5EA')
                .borderRadius(4)
                .margin({ top: 8 })
                .opacity(this.shimmerOpacity)
                .animation({ duration: 750, curve: Curve.EaseInOut })

              Row()
                .width('50%')
                .height(14)
                .backgroundColor('#E5E5EA')
                .borderRadius(4)
                .margin({ top: 8 })
                .opacity(this.shimmerOpacity)
                .animation({ duration: 750, curve: Curve.EaseInOut })
            }
            .width('100%')
            .padding(12)
          }
          .width('100%')
          .borderRadius(16)
          .backgroundColor(Color.White)
          .margin({ bottom: 12 })
        }, (item: number) => item.toString())
      }

      if (this.skeletonType === 'list') {
        Row() {
          ForEach(this.buildCountArray(), (item: number) => {
            Column() {
              Row()
                .width('100%')
                .height(120)
                .backgroundColor('#E5E5EA')
                .borderRadius(8)
                .opacity(this.shimmerOpacity)
                .animation({ duration: 750, curve: Curve.EaseInOut })

              Row()
                .width('80%')
                .height(12)
                .backgroundColor('#E5E5EA')
                .borderRadius(4)
                .margin({ top: 8 })
                .opacity(this.shimmerOpacity)
                .animation({ duration: 750, curve: Curve.EaseInOut })
            }
            .layoutWeight(1)
            .margin({ left: 4, right: 4 })
          }, (item: number) => item.toString())
        }
        .width('100%')
      }

      if (this.skeletonType === 'detail') {
        Column() {
          Row()
            .width('100%')
            .height(200)
            .backgroundColor('#E5E5EA')
            .borderRadius(12)
            .opacity(this.shimmerOpacity)
            .animation({ duration: 750, curve: Curve.EaseInOut })

          Row()
            .width('70%')
            .height(18)
            .backgroundColor('#E5E5EA')
            .borderRadius(4)
            .margin({ top: 16 })
            .opacity(this.shimmerOpacity)
            .animation({ duration: 750, curve: Curve.EaseInOut })

          Row()
            .width('100%')
            .height(14)
            .backgroundColor('#E5E5EA')
            .borderRadius(4)
            .margin({ top: 12 })
            .opacity(this.shimmerOpacity)
            .animation({ duration: 750, curve: Curve.EaseInOut })

          Row()
            .width('100%')
            .height(14)
            .backgroundColor('#E5E5EA')
            .borderRadius(4)
            .margin({ top: 8 })
            .opacity(this.shimmerOpacity)
            .animation({ duration: 750, curve: Curve.EaseInOut })

          Row()
            .width('60%')
            .height(14)
            .backgroundColor('#E5E5EA')
            .borderRadius(4)
            .margin({ top: 8 })
            .opacity(this.shimmerOpacity)
            .animation({ duration: 750, curve: Curve.EaseInOut })
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  private buildCountArray(): number[] {
    const arr: number[] = []
    for (let i: number = 0; i < this.count; i++) {
      arr.push(i)
    }
    return arr
  }
}
