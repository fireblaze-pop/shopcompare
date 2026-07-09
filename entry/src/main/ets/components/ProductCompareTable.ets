import { Product, ProductSpec } from '../models/DataModels'

@Component
export struct ProductCompareTable {
  @Prop products: Product[] = []

  build() {
    if (this.products.length === 0) {
      Text('\u6682\u65E0\u5BF9\u6BD4\u6570\u636E')
        .fontSize(14)
        .fontColor('#8E8E93')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(24)
    } else {
      Scroll() {
        Row() {
          Column() {
            Row()
              .width(100)
              .height(44)
              .backgroundColor('#F9F9F9')

            ForEach(this.buildRowLabels(), (label: string) => {
              Row() {
                Text(label)
                  .fontSize(13)
                  .fontColor('#3C3C3C')
                  .fontWeight(FontWeight.Medium)
              }
              .width(100)
              .height(48)
              .padding({ left: 12, right: 8 })
              .alignItems(VerticalAlign.Center)
              .border({
                width: { bottom: 0.5 },
                color: '#E5E5EA'
              })
            }, (label: string) => label)
          }

          Scroll() {
            Row() {
              ForEach(this.products, (product: Product, colIdx: number) => {
                Column() {
                  Row() {
                    Text(product.brand)
                      .fontSize(13)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#1C1C1E')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width(120)
                  .height(44)
                  .justifyContent(FlexAlign.Center)
                  .padding({ left: 8, right: 8 })
                  .backgroundColor('#F9F9F9')

                  Row() {
                    Text('\u00A5' + product.lowestPrice.toFixed(2))
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF3B30')
                  }
                  .width(120)
                  .height(48)
                  .padding({ left: 8, right: 8 })
                  .alignItems(VerticalAlign.Center)
                  .border({
                    width: { bottom: 0.5 },
                    color: '#E5E5EA'
                  })

                  Row() {
                    Text('\u2605 ' + product.aggregateRating.toFixed(1))
                      .fontSize(13)
                      .fontColor('#1C1C1E')
                  }
                  .width(120)
                  .height(48)
                  .padding({ left: 8, right: 8 })
                  .alignItems(VerticalAlign.Center)
                  .border({
                    width: { bottom: 0.5 },
                    color: '#E5E5EA'
                  })

                  Row() {
                    Text(product.platformCount.toString() + ' \u4E2A\u5E73\u53F0')
                      .fontSize(13)
                      .fontColor('#1C1C1E')
                  }
                  .width(120)
                  .height(48)
                  .padding({ left: 8, right: 8 })
                  .alignItems(VerticalAlign.Center)
                  .border({
                    width: { bottom: 0.5 },
                    color: '#E5E5EA'
                  })

                  ForEach(product.specs.slice(0, 5), (spec: ProductSpec) => {
                    Row() {
                      Text(spec.value)
                        .fontSize(12)
                        .fontColor('#1C1C1E')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width(120)
                    .height(48)
                    .padding({ left: 8, right: 8 })
                    .alignItems(VerticalAlign.Center)
                    .border({
                      width: { bottom: 0.5 },
                      color: '#E5E5EA'
                    })
                  }, (spec: ProductSpec) => spec.key)
                }
              }, (product: Product) => product.id)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .layoutWeight(1)
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Horizontal)
    }
  }

  private buildRowLabels(): string[] {
    const labels: string[] = [
      '\u4EF7\u683C',
      '\u8BC4\u5206',
      '\u5E73\u53F0\u6570',
      '\u89C4\u683C\u53C2\u6570'
    ]
    return labels
  }
}
