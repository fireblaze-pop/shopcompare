import { router } from '@kit.ArkUI'
import { Product } from '../models/DataModels'
import { MockData } from '../data/MockData'
import { NavParams } from '../utils/PreferenceManager'
import { FilterResultCard } from '../components/filter/FilterResultCard'

@Entry
@Component
struct CompareResultPage {
  @State products: Product[] = []
  @State allFilteredProducts: Product[] = []
  @State sortType: string = 'recommend'
  @State isLoading: boolean = true
  @State categoryName: string = ''
  @State selectedBrands: string = ''
  @State selectedPriceLabel: string = ''
  @State selectedOtherLabels: string = ''

  aboutToAppear(): void {
    this.categoryName = NavParams.categoryName
    this.selectedBrands = NavParams.selectedBrands
    this.selectedPriceLabel = NavParams.selectedPriceLabel
    this.selectedOtherLabels = NavParams.selectedOtherLabels

    this.loadData()
  }

  loadData(): void {
    this.isLoading = true

    let allProducts: Product[] = MockData.getProducts()
    let filtered: Product[] = []
    let i: number = 0

    while (i < allProducts.length) {
      let product: Product = allProducts[i]
      let matches: boolean = true

      // 原代码通过 cat1.length > 4 推导分类字段，
      // cat1/cat2 等 ID 永远不满足，导致分类筛选失效。
      // 这里直接使用已传入的 categoryName 匹配 Product.category。
      if (
        this.categoryName.length > 0 &&
        product.category !== this.categoryName
      ) {
        matches = false
      }

      if (
        matches &&
        this.selectedBrands.length > 0 &&
        !this.matchesBrand(product.brand)
      ) {
        matches = false
      }

      if (
        matches &&
        this.selectedPriceLabel.length > 0 &&
        !this.matchesPriceRange(product.lowestPrice)
      ) {
        matches = false
      }

      if (matches) {
        filtered.push(product)
      }

      i = i + 1
    }

    this.allFilteredProducts = filtered
    this.applySort()
    this.isLoading = false
  }

  matchesBrand(brand: string): boolean {
    let brands: string[] =
      this.parseCommaList(this.selectedBrands)

    return brands.indexOf(brand) >= 0
  }

  matchesPriceRange(
    lowestPrice: number
  ): boolean {
    let label: string = this.selectedPriceLabel

    if (label.length === 0) {
      return true
    }

    let belowIndex: number = label.indexOf('以下')

    if (belowIndex >= 0) {
      return lowestPrice <= Number(
        label.substring(0, belowIndex)
      )
    }

    let aboveIndex: number = label.indexOf('以上')

    if (aboveIndex >= 0) {
      return lowestPrice >= Number(
        label.substring(0, aboveIndex)
      )
    }

    let dashIndex: number = label.indexOf('-')

    if (dashIndex >= 0) {
      let minValue: number = Number(
        label.substring(0, dashIndex)
      )

      let maxValue: number = Number(
        label.substring(dashIndex + 1)
      )

      return (
        lowestPrice >= minValue &&
        lowestPrice <= maxValue
      )
    }

    return true
  }

  parseCommaList(str: string): string[] {
    if (str.length === 0) {
      return []
    }

    let result: string[] = []
    let current: string = ''
    let i: number = 0

    while (i < str.length) {
      if (str.charAt(i) === ',') {
        if (current.length > 0) {
          result.push(current)
        }

        current = ''
      } else {
        current = current + str.charAt(i)
      }

      i = i + 1
    }

    if (current.length > 0) {
      result.push(current)
    }

    return result
  }

  applySort(): void {
    let sorted: Product[] = []
    let i: number = 0

    while (i < this.allFilteredProducts.length) {
      sorted.push(this.allFilteredProducts[i])
      i = i + 1
    }

    if (this.sortType === 'recommend') {
      sorted.sort(
        (a: Product, b: Product): number => {
          return b.aggregateScore - a.aggregateScore
        }
      )
    } else if (this.sortType === 'priceLow') {
      sorted.sort(
        (a: Product, b: Product): number => {
          return a.lowestPrice - b.lowestPrice
        }
      )
    } else if (this.sortType === 'rating') {
      sorted.sort(
        (a: Product, b: Product): number => {
          return b.aggregateRating - a.aggregateRating
        }
      )
    }

    this.products = sorted
  }

  changeSort(type: string): void {
    if (this.sortType === type) {
      return
    }

    this.sortType = type
    this.applySort()
  }

  getPlatformCount(): number {
    let platformNames: string[] = []
    let i: number = 0

    while (i < this.products.length) {
      let j: number = 0

      while (
        j <
        this.products[i].platformListings.length
      ) {
        let name: string =
          this.products[i].platformListings[j].platform

        if (platformNames.indexOf(name) < 0) {
          platformNames.push(name)
        }

        j = j + 1
      }

      i = i + 1
    }

    return platformNames.length
  }

  getSelectedFilterLabels(): string[] {
    let labels: string[] = []
    let brands: string[] =
      this.parseCommaList(this.selectedBrands)

    let i: number = 0

    while (i < brands.length) {
      labels.push(brands[i])
      i = i + 1
    }

    if (this.selectedPriceLabel.length > 0) {
      labels.push('¥' + this.selectedPriceLabel)
    }

    let others: string[] =
      this.parseCommaList(this.selectedOtherLabels)

    let j: number = 0

    while (j < others.length) {
      labels.push(others[j])
      j = j + 1
    }

    return labels
  }

  navigateToDetail(product: Product): void {
    NavParams.productId = product.id

    router.pushUrl({
      url: 'pages/ProductDetailPage'
    })
  }

  navigateBackToFilter(): void {
    router.back()
  }

  @Builder
  buildTopBar(): void {
    Row() {
      Column() {
        Image($r('app.media.filter_back'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
      .width(40)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        router.back()
      })

      Column({ space: 2 }) {
        Text(this.categoryName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Text('筛选结果')
          .fontSize(11)
          .fontColor('#8E8E93')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row({ space: 6 }) {
        Image($r('app.media.filter_tune'))
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)

        Text('筛选')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5267E8')
      }
      .height(38)
      .padding({
        left: 11,
        right: 12
      })
      .backgroundColor('#EEF1FF')
      .borderRadius(12)
      .onClick(() => {
        this.navigateBackToFilter()
      })
    }
    .width('100%')
    .height(64)
    .padding({
      left: 8,
      right: 14
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  @Builder
  buildFilterSummary(): void {
    Column() {
      Text(
        '找到 ' +
        this.products.length.toString() +
        ' 件商品 · 覆盖 ' +
        this.getPlatformCount().toString() +
        ' 个平台'
      )
        .fontSize(13)
        .fontColor('#8E8E93')
        .width('100%')

      if (this.getSelectedFilterLabels().length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(
              this.getSelectedFilterLabels(),
              (label: string) => {
                Text(label)
                  .fontSize(12)
                  .fontColor('#5267E8')
                  .padding({
                    left: 10,
                    right: 10,
                    top: 6,
                    bottom: 6
                  })
                  .backgroundColor('#EEF1FF')
                  .borderRadius(9)
              },
              (label: string) => label
            )
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 14,
      bottom: 12
    })
    .backgroundColor('#F5F6F8')
  }

  @Builder
  buildSortTabs(): void {
    Row({ space: 8 }) {
      this.buildSortTabItem(
        'recommend',
        '综合推荐'
      )

      this.buildSortTabItem(
        'priceLow',
        '价格最低'
      )

      this.buildSortTabItem(
        'rating',
        '评分最高'
      )
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 12
    })
    .backgroundColor('#F5F6F8')
  }

  @Builder
  buildSortTabItem(
    type: string,
    label: string
  ): void {
    Text(label)
      .fontSize(13)
      .fontWeight(
        this.sortType === type ?
        FontWeight.Medium :
        FontWeight.Normal
      )
      .fontColor(
        this.sortType === type ?
        Color.White :
        '#5E6168'
      )
      .height(38)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(
        this.sortType === type ?
        '#5267E8' :
        Color.White
      )
      .border({
        width: 1,
        color:
          this.sortType === type ?
          '#5267E8' :
          '#E8EAF0'
      })
      .borderRadius(12)
      .onClick(() => {
        this.changeSort(type)
      })
  }

  @Builder
  buildEmptyState(): void {
    Column({ space: 14 }) {
      Column() {
        Image($r('app.media.filter_empty'))
          .width(42)
          .height(42)
          .objectFit(ImageFit.Contain)
      }
      .width(76)
      .height(76)
      .borderRadius(24)
      .backgroundColor('#EEF1FF')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text('没有找到匹配的商品')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1C1E')

      Text('调整筛选条件后再试试')
        .fontSize(13)
        .fontColor('#8E8E93')

      Button('重新筛选')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#5267E8')
        .backgroundColor(Color.White)
        .border({
          width: 1,
          color: '#5267E8'
        })
        .height(42)
        .padding({
          left: 28,
          right: 28
        })
        .borderRadius(13)
        .onClick(() => {
          router.back()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F6F8')
  }

  @Builder
  buildSkeletonList(): void {
    List({ space: 12 }) {
      ForEach(
        [0, 1, 2, 3],
        (item: number) => {
          ListItem() {
            Row() {
              Column()
                .width(92)
                .height(100)
                .borderRadius(14)
                .backgroundColor('#E9EBF0')

              Column() {
                Row()
                  .width('72%')
                  .height(16)
                  .borderRadius(5)
                  .backgroundColor('#E9EBF0')

                Row()
                  .width('48%')
                  .height(12)
                  .borderRadius(5)
                  .backgroundColor('#E9EBF0')
                  .margin({ top: 10 })

                Row()
                  .width('62%')
                  .height(18)
                  .borderRadius(5)
                  .backgroundColor('#E9EBF0')
                  .margin({ top: 14 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 14 })
            }
            .width('100%')
            .padding(14)
            .backgroundColor(Color.White)
            .borderRadius(16)
          }
        }
      )
    }
    .width('100%')
    .layoutWeight(1)
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 18
    })
    .backgroundColor('#F5F6F8')
    .scrollBar(BarState.Off)
  }

  @Builder
  buildBottomActions(): void {
    Row({ space: 12 }) {
      Button('详细对比表')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#5267E8')
        .backgroundColor(Color.White)
        .borderRadius(14)
        .border({
          width: 1,
          color: '#5267E8'
        })
        .layoutWeight(1)
        .height(48)
        .onClick(() => {
          NavParams.categoryId = NavParams.categoryId
          NavParams.categoryName = this.categoryName
          NavParams.selectedBrands = this.selectedBrands
          NavParams.selectedPriceLabel =
            this.selectedPriceLabel

          router.pushUrl({
            url: 'pages/CompareTablePage'
          })
        })

      Button('只看最低价')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor('#5267E8')
        .borderRadius(14)
        .layoutWeight(1)
        .height(48)
        .onClick(() => {
          this.navigateToCheapest()
        })
    }
    .width('100%')
    .height(68)
    .padding({
      left: 16,
      right: 16,
      top: 10,
      bottom: 10
    })
    .backgroundColor(Color.White)
  }

  navigateToCheapest(): void {
    if (this.allFilteredProducts.length === 0) {
      return
    }

    let cheapest: Product =
      this.allFilteredProducts[0]

    let i: number = 1

    while (
      i < this.allFilteredProducts.length
    ) {
      if (
        this.allFilteredProducts[i].lowestPrice <
        cheapest.lowestPrice
      ) {
        cheapest = this.allFilteredProducts[i]
      }

      i = i + 1
    }

    this.navigateToDetail(cheapest)
  }

  build() {
    Column() {
      this.buildTopBar()

      if (this.isLoading) {
        this.buildSkeletonList()
      } else if (this.products.length === 0) {
        this.buildEmptyState()
      } else {
        this.buildFilterSummary()
        this.buildSortTabs()

        List({ space: 12 }) {
          ForEach(
            this.products,
            (
              product: Product,
              index: number
            ) => {
              ListItem() {
                FilterResultCard({
                  product: product,
                  onProductAction: (
                    selected: Product
                  ): void => {
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
        .backgroundColor('#F5F6F8')
        .scrollBar(BarState.Off)

        this.buildBottomActions()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
