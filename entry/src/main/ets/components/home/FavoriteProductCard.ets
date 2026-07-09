import { Product } from '../../models/DataModels'

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
export struct FavoriteProductCard {
  @Prop product: Product = emptyProduct()

  onViewCompare: (product: Product) => void =
    (product: Product): void => {}

  onRemoveFavorite: (product: Product) => void =
    (product: Product): void => {}

  build() {
    Column() {
      Row() {
        Column() {
          if (this.product.imageUrl.length > 0) {
            Image(this.product.imageUrl)
              .width(82)
              .height(82)
              .objectFit(ImageFit.Contain)
          } else {
            Image($r('app.media.icon_product_placeholder'))
              .width(36)
              .height(36)
              .objectFit(ImageFit.Contain)
          }
        }
        .width(92)
        .height(92)
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

          Text(this.product.brand + ' · ' + this.product.category)
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ top: 5 })

          Text('¥' + this.product.lowestPrice.toFixed(2))
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF3B30')
            .margin({ top: 8 })

          Text(
            '当前最低 · ' +
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

      Row({ space: 10 }) {
        Button('查看比价')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#5267E8')
          .height(38)
          .layoutWeight(1)
          .borderRadius(12)
          .onClick(() => {
            this.onViewCompare(this.product)
          })

        Button('取消收藏')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FF3B30')
          .backgroundColor('#FFF4F3')
          .height(38)
          .layoutWeight(1)
          .borderRadius(12)
          .onClick(() => {
            this.onRemoveFavorite(this.product)
          })
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
  }
}
