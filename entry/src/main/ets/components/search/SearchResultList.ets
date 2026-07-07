import { Product } from '../../models/DataModels'
import { SearchProductItem } from './SearchProductItem'

@Component
export struct SearchResultList {
  @Prop products: Product[] = []

  onProductClick: (product: Product) => void =
    (product: Product): void => {}

  build() {
    Scroll() {
      Column() {
        Text(
          '搜索结果（' +
          this.products.length.toString() +
          '）'
        )
          .fontSize(13)
          .fontColor('#8E8E93')
          .width('100%')
          .padding({
            left: 16,
            top: 12,
            bottom: 8
          })

        ForEach(this.products, (product: Product) => {
          SearchProductItem({
            product: product,
            onProductClick: (clickedProduct: Product): void => {
              this.onProductClick(clickedProduct)
            }
          })
        }, (product: Product) => product.id)
      }
      .width('100%')
      .padding({
        bottom: 20
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
    .scrollBar(BarState.Off)
  }
}
