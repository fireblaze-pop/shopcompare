import { Category } from '../models/DataModels'

@Component
export struct CategoryIconGrid {
  @Prop categories: Category[] = []
  @Prop columns: number = 4
  onCategoryClick: (category: Category) => void = (category: Category) => {}

  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.categories, (item: Category) => {
        Column() {
          Text(item.icon)
            .fontSize(24)
            .width(48)
            .height(48)
            .textAlign(TextAlign.Center)
            .borderRadius(24)
            .backgroundColor('#F2F2F7')

          Text(item.name)
            .fontSize(12)
            .fontColor('#3C3C3C')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 6 })
        }
        .width(this.calcItemWidth())
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 16 })
        .onClick(() => {
          this.onCategoryClick(item)
        })
      }, (item: Category) => item.id)
    }
    .width('100%')
  }

  private calcItemWidth(): string {
    return (100 / this.columns).toFixed(2) + '%'
  }
}
