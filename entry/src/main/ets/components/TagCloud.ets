import { ReviewTag } from '../models/DataModels'

@Component
export struct TagCloud {
  @Prop tags: ReviewTag[] = []
  @Prop maxHeight: number = 120

  build() {
    Scroll() {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.tags, (tag: ReviewTag, index: number) => {
          Text(tag.text + ' ' + tag.count.toString())
            .fontSize(12)
            .fontColor(tag.type === 1 ? '#34C759' : '#FF3B30')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .borderRadius(12)
            .backgroundColor(tag.type === 1 ? '#1534C759' : '#15FF3B30')
            .margin({ right: 8, bottom: 8 })
        }, (tag: ReviewTag, index: number) => index.toString())
      }
      .width('100%')
    }
    .scrollable(ScrollDirection.Vertical)
    .constraintSize({ maxHeight: this.maxHeight })
  }
}
