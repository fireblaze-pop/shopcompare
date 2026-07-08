import { Product } from '../../models/DataModels'
import { SearchProductItem } from './SearchProductItem'

@Component
export struct SearchResultList {
  @Prop products: Product[] = []

  onProductClick: (product: Product) => void =
    (product: Product): void => {}

  build() {
    Column() {
      Row() {
        Text(
          '搜索结果（' +
            this.products.length.toString() +
            '）'
        )
          .fontSize(13)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .height(44)
      .padding({
        left: 16,
        right: 16
      })
      .alignItems(VerticalAlign.Center)

      List({ space: 10 }) {
        ForEach(
          this.products,
          (product: Product) => {
            ListItem() {
              SearchProductItem({
                product: product,
                onProductClick: (
                  clickedProduct: Product
                ): void => {
                  this.onProductClick(clickedProduct)
                }
              })
            }
          },
          (product: Product) => product.id
        )
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        bottom: 20
      })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#F5F6F8')
  }
}