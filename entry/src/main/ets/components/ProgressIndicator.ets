@Component
export struct ProgressIndicator {
  @Prop totalSteps: number = 3
  @Prop currentStep: number = 0

  build() {
    Row() {
      ForEach(this.buildSteps(), (step: StepItem, index: number) => {
        Row() {
          Column() {
            if (index < this.currentStep) {
              Text('\u2713')
                .fontSize(12)
                .fontColor(Color.White)
            } else {
              Text((index + 1).toString())
                .fontSize(12)
                .fontColor(index === this.currentStep ? Color.White : '#8E8E93')
            }
          }
          .width(24)
          .height(24)
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(step.isActive || index < this.currentStep ? '#007AFF' : '#E5E5EA')

          Text(step.label)
            .fontSize(10)
            .fontColor(step.isActive ? '#007AFF' : '#8E8E93')
            .margin({ top: 4 })
            .textAlign(TextAlign.Center)
        }
        .alignItems(HorizontalAlign.Center)

        if (index < this.totalSteps - 1) {
          Divider()
            .vertical(true)
            .height(2)
            .width(24)
            .color(index < this.currentStep ? '#007AFF' : '#E5E5EA')
            .margin({ left: 4, right: 4 })
        }
      }, (step: StepItem) => step.index.toString())
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  private buildSteps(): StepItem[] {
    const steps: StepItem[] = []
    for (let i: number = 0; i < this.totalSteps; i++) {
      const item: StepItem = {
        index: i,
        label: (i + 1).toString(),
        isActive: i === this.currentStep
      }
      steps.push(item)
    }
    return steps
  }
}

interface StepItem {
  index: number
  label: string
  isActive: boolean
}
