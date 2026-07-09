import { Product } from '../../models/DataModels'
import { formatPrice } from '../../utils/FormatUtils'

function emptyProduct(): Product {
  return {
    id: '',
    name: '',
    modelCode: '',
    brand: '',
    category: '',
    imageUrl: '',
    specs: [],
    aggregateScore: 0,
    aggregateRating: 0,
    totalReviewCount: 0,
    platformListings: [],
    lowestPrice: 0,
    priceSpread: 0,
    historicalLow: 0,
    priceHistory: [],
    reviewTags: [],
    publishDate: '',
    description: ''
  }
}

@Component
export struct SearchProductItem {
  @Prop product: Product = emptyProduct()

  onProductClick: (product: Product) => void =
    (product: Product): void => {}

  build() {
    Row() {
      Column() {
        if (this.product.imageUrl !== undefined && this.product.imageUrl.length > 0) {
          Image(this.product.imageUrl)
            .width(64)
            .height(64)
            .objectFit(ImageFit.Cover)
        } else {
          Text('\uD83D\uDCE6')
            .fontSize(28)
        }
      }
      .width(64)
      .height(64)
      .borderRadius(8)
      .backgroundColor('#F2F2F7')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text(this.product.name)
          .fontSize(15)
          .fontWeight(500)
          .fontColor('#1C1C1E')
          .maxLines(1)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .width('100%')

        Row() {
          Text(this.product.brand)
            .fontSize(12)
            .fontColor('#8E8E93')

          Text(' · ' + this.product.category)
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .margin({
          top: 4
        })

        Row() {
          Text(formatPrice(this.product.lowestPrice))
            .fontSize(16)
            .fontWeight(700)
            .fontColor('#FF3B30')

          Text('起')
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({
              left: 4
            })
        }
        .margin({
          top: 4
        })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({
        left: 12
      })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({
      left: 16,
      right: 16,
      top: 6,
      bottom: 0
    })
    .onClick(() => {
      this.onProductClick(this.product)
    })
  }
}
