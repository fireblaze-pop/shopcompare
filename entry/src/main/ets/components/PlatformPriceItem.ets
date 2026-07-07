import { PlatformListing } from '../models/DataModels'

function emptyListing(): PlatformListing {
  const listing: PlatformListing = {
    platform: '',
    price: 0,
    rating: 0,
    reviewCount: 0,
    inStock: false,
    url: ''
  }
  return listing
}

@Component
export struct PlatformPriceItem {
  @Prop listing: PlatformListing = emptyListing()
  @Prop isLowest: boolean = false
  onViewClick: () => void = () => {}

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.listing.platform)
            .fontSize(15)
            .fontColor('#1C1C1E')
            .fontWeight(FontWeight.Medium)

          if (this.listing.rating > 0) {
            Row() {
              Text('\u2605 ' + this.listing.rating.toFixed(1))
                .fontSize(11)
                .fontColor('#FFB800')

              Text('(' + this.listing.reviewCount.toString() + ')')
                .fontSize(10)
                .fontColor('#8E8E93')
            }
            .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Text('\u00A5' + this.listing.price.toFixed(2))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isLowest ? '#FF3B30' : '#1C1C1E')

          if (!this.listing.inStock) {
            Text('\u7F3A\u8D27')
              .fontSize(11)
              .fontColor('#FF3B30')
              .margin({ top: 2 })
          } else {
            Text('\u6709\u8D27')
              .fontSize(11)
              .fontColor('#34C759')
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.End)

        Text('\u67E5\u770B')
          .fontSize(13)
          .fontColor('#007AFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .border({ width: 1, color: '#007AFF' })
          .margin({ left: 12 })
          .onClick(() => {
            this.onViewClick()
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ top: 14, bottom: 14 })

      Divider()
        .strokeWidth(0.5)
        .color('#E5E5EA')
    }
    .width('100%')
  }
}
