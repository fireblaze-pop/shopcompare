import { router } from '@kit.ArkUI'
import { Product } from '../../models/DataModels'
import { MockData } from '../../data/MockData'
import { NavParams } from '../../utils/PreferenceManager'
import { DiscoverProductCard } from './DiscoverProductCard'

@Component
export struct DiscoverContent {
  @State activeSortIndex: number = 0

  build() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text('发现')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text('主动探索全站好物，不只看算法推荐')
            .fontSize(13)
            .fontColor('#8E8E93')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Image($r('app.media.icon_search'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
        }
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor(Color.White)
        .border({
          width: 1,
          color: '#E8EAF0'
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/SearchPage'
          })
        })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 18,
        bottom: 16
      })

      Scroll() {
        Row({ space: 10 }) {
          this.SortChip(0, '热门')
          this.SortChip(1, '高评分')
          this.SortChip(2, '低价')
          this.SortChip(3, '价差大')
        }
        .padding({
          left: 16,
          right: 16
        })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .margin({ bottom: 10 })

      List({ space: 12 }) {
        ForEach(
          this.getDisplayProducts(),
          (product: Product) => {
            ListItem() {
              DiscoverProductCard({
                product: product,
                onProductAction: (selected: Product): void => {
                  this.navigateToDetail(selected)
                }
              })
                .margin({
                  left: 16,
                  right: 16
                })
            }
          },
          (product: Product) => product.id
        )
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        top: 2,
        bottom: 18
      })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  @Builder SortChip(index: number, label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(
        this.activeSortIndex === index ?
        FontWeight.Medium :
        FontWeight.Normal
      )
      .fontColor(
        this.activeSortIndex === index ?
        Color.White :
        '#5E6168'
      )
      .padding({
        left: 17,
        right: 17,
        top: 8,
        bottom: 8
      })
      .backgroundColor(
        this.activeSortIndex === index ?
        '#5267E8' :
        Color.White
      )
      .border({
        width: 1,
        color:
          this.activeSortIndex === index ?
          '#5267E8' :
          '#E8EAF0'
      })
      .borderRadius(18)
      .onClick(() => {
        this.activeSortIndex = index
      })
  }

  private getDisplayProducts(): Product[] {
    let source: Product[] = MockData.getProducts()
    let result: Product[] = []
    let i: number = 0

    while (i < source.length) {
      result.push(source[i])
      i = i + 1
    }

    let outer: number = 0
    while (outer < result.length - 1) {
      let inner: number = 0

      while (inner < result.length - 1 - outer) {
        if (this.shouldSwap(result[inner], result[inner + 1])) {
          let temp: Product = result[inner]
          result[inner] = result[inner + 1]
          result[inner + 1] = temp
        }

        inner = inner + 1
      }

      outer = outer + 1
    }

    return result
  }

  private shouldSwap(
    left: Product,
    right: Product
  ): boolean {
    if (this.activeSortIndex === 1) {
      return left.aggregateRating < right.aggregateRating
    }

    if (this.activeSortIndex === 2) {
      return left.lowestPrice > right.lowestPrice
    }

    if (this.activeSortIndex === 3) {
      return left.priceSpread < right.priceSpread
    }

    return left.aggregateScore < right.aggregateScore
  }

  private navigateToDetail(product: Product): void {
    NavParams.productId = product.id

    router.pushUrl({
      url: 'pages/ProductDetailPage',
      params: {
        productId: product.id
      }
    })
  }
}
