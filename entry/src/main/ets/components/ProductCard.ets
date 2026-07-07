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
  onCardClick: () => void = () => {}

  build() {
    Column() {
      Row() {
        if (this.product.imageUrl.length > 0) {
          Image(this.product.imageUrl)
            .width('100%')
            .height(160)
            .objectFit(ImageFit.Cover)
        }
        if (this.product.imageUrl.length === 0) {
          Text('\uD83D\uDCE6')
            .fontSize(48)
        }
      }
      .width('100%')
      .height(160)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F2F2F7')

      Column() {
        Text(this.product.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1C1E')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(this.product.brand)
            .fontSize(11)
            .fontColor('#007AFF')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#0A007AFF')
            .borderRadius(4)
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
          Text('\u00A5' + this.product.lowestPrice.toFixed(2))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF3B30')

          Text('\u8D77')
            .fontSize(13)
            .fontColor('#8E8E93')
            .margin({ left: 2 })
        }
        .margin({ top: 8 })
        .alignItems(VerticalAlign.Bottom)

        Row() {
          if (this.product.priceSpread > 0) {
            Text('\u4EF7\u5DEE \u00A5' + this.product.priceSpread.toFixed(2))
              .fontSize(12)
              .fontColor('#8E8E93')
          }
        }
        .margin({ top: 4 })

        if (this.showPlatforms) {
          Text(this.product.platformListings.length.toString() + ' \u4E2A\u5E73\u53F0\u5728\u552E')
            .fontSize(12)
            .fontColor('#3C3C3C')
            .margin({ top: 6 })
        }
      }
      .width('100%')
      .padding(12)
    }
    .width(this.cardWidth > 0 ? this.cardWidth : '100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({
      radius: 8,
      offsetY: 2,
      color: '#1A000000'
    })
    .onClick(() => {
      this.onCardClick()
    })
  }
}
