import { Product } from '../../models/DataModels'
import { StarRating } from '../StarRating'

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
    platformCount: 0,
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
export struct DiscoverProductCard {
  @Prop product: Product = emptyProduct()

  onProductAction: (product: Product) => void =
    (product: Product): void => {}

  build() {
    Row() {
      Column() {
        if (this.product.imageUrl.length > 0) {
          Image(this.product.imageUrl)
            .width(94)
            .height(94)
            .objectFit(ImageFit.Contain)
        } else {
          Image($r('app.media.icon_product_placeholder'))
            .width(38)
            .height(38)
            .objectFit(ImageFit.Contain)
        }
      }
      .width(104)
      .height(112)
      .borderRadius(14)
      .backgroundColor('#F7F8FA')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row({ space: 6 }) {
          Text(this.product.brand)
            .fontSize(11)
            .fontColor('#5267E8')
            .padding({
              left: 7,
              right: 7,
              top: 2,
              bottom: 2
            })
            .backgroundColor('#EEF1FF')
            .borderRadius(5)

          Text(this.product.category)
            .fontSize(11)
            .fontColor('#8E8E93')
        }

        Text(this.product.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1C1E')
          .maxLines(2)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .width('100%')
          .margin({ top: 7 })

        StarRating({
          rating: this.product.aggregateRating,
          starIconSize: 11,
          showScore: true,
          reviewCount: this.product.totalReviewCount
        })
          .margin({ top: 5 })

        Row() {
          Text('¥' + this.product.lowestPrice.toFixed(2))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF3B30')

          Text('最低价')
            .fontSize(11)
            .fontColor('#FF3B30')
            .padding({
              left: 6,
              right: 6,
              top: 2,
              bottom: 2
            })
            .backgroundColor('#FFF1F0')
            .borderRadius(5)
            .margin({ left: 7 })
        }
        .alignItems(VerticalAlign.Center)
        .margin({ top: 7 })

        Text(
          this.product.platformCount.toString() +
          '个平台 · 价差 ¥' +
          this.product.priceSpread.toFixed(2)
        )
          .fontSize(12)
          .fontColor('#8E8E93')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .onClick(() => {
      this.onProductAction(this.product)
    })
  }
}
