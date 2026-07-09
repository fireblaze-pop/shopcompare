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
export struct FilterResultCard {
  @Prop product: Product = emptyProduct()

  onProductAction: (
    product: Product
  ) => void = (
    product: Product
  ): void => {}

  build() {
    Row() {
      Column() {
        if (this.product.imageUrl.length > 0) {
          Image(this.product.imageUrl)
            .width(82)
            .height(82)
            .objectFit(ImageFit.Contain)
        } else {
          Image($r('app.media.filter_product_placeholder'))
            .width(36)
            .height(36)
            .objectFit(ImageFit.Contain)
        }
      }
      .width(92)
      .height(100)
      .borderRadius(14)
      .backgroundColor('#F7F8FA')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text(this.product.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1C1E')
          .maxLines(2)
          .textOverflow({
            overflow: TextOverflow.Ellipsis
          })
          .width('100%')

        Text(
          this.product.brand +
          ' · ' +
          this.product.category
        )
          .fontSize(12)
          .fontColor('#8E8E93')
          .margin({ top: 5 })

        Row() {
          Text('★ ' + this.product.aggregateRating.toFixed(1))
            .fontSize(12)
            .fontColor('#FF9500')

          Text(
            ' · ' +
            this.product.totalReviewCount.toString() +
            ' 条评价'
          )
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .margin({ top: 7 })

        Row() {
          Text(formatPrice(this.product.lowestPrice))
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF3B30')

          Text('全网最低')
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF3B30')
            .padding({
              left: 7,
              right: 7,
              top: 3,
              bottom: 3
            })
            .backgroundColor('#FFF1F0')
            .borderRadius(6)
            .margin({ left: 7 })
        }
        .alignItems(VerticalAlign.Center)
        .margin({ top: 7 })

        Row() {
          Text(
            '价差 ' +
            formatPrice(this.product.priceSpread)
          )
            .fontSize(11)
            .fontColor('#2D8A4E')
            .padding({
              left: 8,
              right: 8,
              top: 3,
              bottom: 3
            })
            .backgroundColor('#EEF9F1')
            .borderRadius(7)

          Blank()

          Text(
            this.product.platformCount.toString() +
            ' 个平台在售'
          )
            .fontSize(11)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .margin({ top: 8 })
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
