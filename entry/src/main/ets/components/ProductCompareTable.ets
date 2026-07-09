import { Product, ProductSpec } from '../models/DataModels'
import { formatPrice } from '../utils/FormatUtils'

@Component
export struct ProductCompareTable {
  @Prop products: Product[] = []

  private getSpecKeys(): string[] {
    let keys: string[] = []
    let productIndex: number = 0

    while (productIndex < this.products.length) {
      let specs: ProductSpec[] = this.products[productIndex].specs
      let specIndex: number = 0

      while (specIndex < specs.length && keys.length < 6) {
        let key: string = specs[specIndex].key
        if (
          key.length > 0 &&
          keys.indexOf(key) < 0
        ) {
          keys.push(key)
        }
        specIndex = specIndex + 1
      }

      if (keys.length >= 6) {
        break
      }

      productIndex = productIndex + 1
    }

    return keys
  }

  private getSpecValue(
    product: Product,
    key: string
  ): string {
    let i: number = 0

    while (i < product.specs.length) {
      if (product.specs[i].key === key) {
        if (product.specs[i].value.length > 0) {
          return product.specs[i].value
        }
        return '—'
      }
      i = i + 1
    }

    return '—'
  }

  private getLowestSelectedPrice(): number {
    let lowest: number = 0
    let i: number = 0

    while (i < this.products.length) {
      let price: number = this.products[i].lowestPrice
      if (
        price > 0 &&
        (lowest === 0 || price < lowest)
      ) {
        lowest = price
      }
      i = i + 1
    }

    return lowest
  }

  private isLowestPrice(product: Product): boolean {
    let lowest: number = this.getLowestSelectedPrice()
    return (
      lowest > 0 &&
      product.lowestPrice === lowest
    )
  }

  @Builder
  buildLabelCell(
    label: string,
    cellHeight: number
  ): void {
    Row() {
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#5E6168')
        .maxLines(2)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
    }
    .width(92)
    .height(cellHeight)
    .padding({ left: 12, right: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
    .border({
      width: {
        right: 1,
        bottom: 1
      },
      color: '#ECEEF2'
    })
  }

  @Builder
  buildMetricCell(
    value: string,
    fontColor: string,
    emphasize: boolean,
    cellHeight: number
  ): void {
    Row() {
      Text(value)
        .fontSize(13)
        .fontWeight(
          emphasize ?
          FontWeight.Bold :
          FontWeight.Normal
        )
        .fontColor(fontColor)
        .maxLines(2)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
        .textAlign(TextAlign.Center)
    }
    .width(156)
    .height(cellHeight)
    .padding({ left: 10, right: 10 })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
    .border({
      width: {
        right: 1,
        bottom: 1
      },
      color: '#ECEEF2'
    })
  }

  @Builder
  buildProductHeader(product: Product): void {
    Column() {
      Column() {
        if (product.imageUrl.length > 0) {
          Image(product.imageUrl)
            .width(72)
            .height(72)
            .objectFit(ImageFit.Contain)
        } else {
          Image($r('app.media.filter_product_placeholder'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
        }
      }
      .width(82)
      .height(82)
      .borderRadius(14)
      .backgroundColor('#F7F8FA')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(product.brand.length > 0 ? product.brand : '未知品牌')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#5267E8')
        .margin({ top: 8 })
        .maxLines(1)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })

      Text(product.name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1C1E')
        .maxLines(2)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
        .textAlign(TextAlign.Center)
        .margin({ top: 3 })
        .width(136)

      if (this.isLowestPrice(product)) {
        Text('当前最低')
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
          .margin({ top: 5 })
      }
    }
    .width(156)
    .height(184)
    .padding({ top: 10, bottom: 8 })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .border({
      width: {
        right: 1,
        bottom: 1
      },
      color: '#ECEEF2'
    })
  }

  @Builder
  buildLabelColumn(specKeys: string[]): void {
    Column() {
      Column({ space: 4 }) {
        Text('对比维度')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Text('横向滑动')
          .fontSize(11)
          .fontColor('#8E8E93')
      }
      .width(92)
      .height(184)
      .padding({ left: 12, right: 8 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#F7F8FA')
      .border({
        width: {
          right: 1,
          bottom: 1
        },
        color: '#ECEEF2'
      })

      this.buildLabelCell('当前最低价', 58)
      this.buildLabelCell('综合分', 58)
      this.buildLabelCell('在售平台', 58)
      this.buildLabelCell('评价数量', 58)
      this.buildLabelCell('平台价差', 58)
      this.buildLabelCell('历史低价', 58)

      if (specKeys.length > 0) {
        Row() {
          Text('规格参数')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#5267E8')
        }
        .width(92)
        .height(36)
        .padding({ left: 12 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#EEF1FF')
        .border({
          width: {
            right: 1,
            bottom: 1
          },
          color: '#DDE2FF'
        })

        ForEach(
          specKeys,
          (key: string) => {
            this.buildLabelCell(key, 60)
          },
          (key: string) => key
        )
      }
    }
    .width(92)
  }

  @Builder
  buildProductColumn(
    product: Product,
    specKeys: string[]
  ): void {
    Column() {
      this.buildProductHeader(product)

      this.buildMetricCell(
        formatPrice(product.lowestPrice),
        '#FF3B30',
        true,
        58
      )

      this.buildMetricCell(
        product.aggregateScore.toFixed(1) + ' / 10',
        '#1C1C1E',
        true,
        58
      )

      this.buildMetricCell(
        product.platformCount.toString() + ' 个平台',
        '#1C1C1E',
        false,
        58
      )

      this.buildMetricCell(
        product.totalReviewCount.toString() + ' 条',
        '#1C1C1E',
        false,
        58
      )

      this.buildMetricCell(
        formatPrice(product.priceSpread),
        '#2D8A4E',
        false,
        58
      )

      this.buildMetricCell(
        formatPrice(product.historicalLow),
        '#1C1C1E',
        false,
        58
      )

      if (specKeys.length > 0) {
        Row()
          .width(156)
          .height(36)
          .backgroundColor('#EEF1FF')
          .border({
            width: {
              right: 1,
              bottom: 1
            },
            color: '#DDE2FF'
          })

        ForEach(
          specKeys,
          (key: string) => {
            this.buildMetricCell(
              this.getSpecValue(product, key),
              '#1C1C1E',
              false,
              60
            )
          },
          (key: string) => key
        )
      }
    }
    .width(156)
  }

  build() {
    if (this.products.length === 0) {
      Text('暂无对比数据')
        .fontSize(14)
        .fontColor('#8E8E93')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(24)
    } else {
      Row() {
        this.buildLabelColumn(this.getSpecKeys())

        Scroll() {
          Row() {
            ForEach(
              this.products,
              (product: Product) => {
                this.buildProductColumn(
                  product,
                  this.getSpecKeys()
                )
              },
              (product: Product) => product.id
            )
          }
          .alignItems(VerticalAlign.Top)
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
  }
}
