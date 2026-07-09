import { Product } from '../models/DataModels'
import { StarRating } from './StarRating'

function emptyProduct(): Product {
  let product: Product = {
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

  return product
}

@Component
export struct ProductCard {
  @Prop product: Product = emptyProduct()
  @Prop showPlatforms: boolean = true
  @Prop cardWidth: number = 0

  onCardClick: () => void = (): void => {}

  build() {
    Column() {
      Row() {
        if (this.product.imageUrl.length > 0) {
          Image(this.product.imageUrl)
            .width('100%')
            .height(152)
            .objectFit(ImageFit.Contain)
        } else {
          Image($r('app.media.icon_product_placeholder'))
            .width(44)
            .height(44)
            .objectFit(ImageFit.Contain)
        }
      }
      .width('100%')
      .height(152)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#F7F8FA')

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

        Row() {
          Text(this.product.brand)
            .fontSize(11)
            .fontColor('#5267E8')
            .padding({
              left: 8,
              right: 8,
              top: 2,
              bottom: 2
            })
            .backgroundColor('#EEF1FF')
            .borderRadius(5)
        }
        .margin({ top: 8 })

        Row() {
          StarRating({
            rating: this.product.aggregateRating,
            starIconSize: 12,
            showScore: true,
            reviewCount: this.product.totalReviewCount
          })
        }
        .margin({ top: 6 })

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
        .margin({ top: 8 })
        .alignItems(VerticalAlign.Center)

        if (this.showPlatforms) {
          Text(
            this.product.platformCount.toString() +
            '个平台 · 价差 ¥' +
            this.product.priceSpread.toFixed(2)
          )
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ top: 6 })
        }
      }
      .width('100%')
      .padding(12)
    }
    .width(this.cardWidth > 0 ? this.cardWidth : '100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .onClick(() => {
      this.onCardClick()
    })
  }
}
