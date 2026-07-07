import { Category } from '../models/DataModels'

@Component
export struct CategoryIconGrid {
  @Prop categories: Category[] = []
  @Prop columns: number = 3

  onCategoryClick: (category: Category) => void =
    (category: Category): void => {}

  @Builder IconBuilder(index: number) {
    if (index === 0) {
      Image($r('app.media.category_phone'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 1) {
      Image($r('app.media.category_laptop'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 2) {
      Image($r('app.media.category_appliance'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 3) {
      Image($r('app.media.category_beauty'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 4) {
      Image($r('app.media.category_clothing'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else {
      Image($r('app.media.category_food'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    }
  }

  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.categories, (item: Category, index: number) => {
        Column({ space: 8 }) {
          Column() {
            this.IconBuilder(index)
          }
          .width(54)
          .height(54)
          .borderRadius(16)
          .backgroundColor('#EEF1FF')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Text(item.name)
            .fontSize(13)
            .fontColor('#3C3C43')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
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
