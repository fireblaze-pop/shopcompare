import { router } from '@kit.ArkUI'
import { Product } from '../models/DataModels'
import { DataProvider } from '../data/DataProvider'
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
  @State summaryHeight: number = 46
  @State summaryOpacity: number = 1
  @State summaryBottomMargin: number = 0
  @State showSummaryBanner: boolean = true
  @State showSortExpanded: boolean = true

  private summaryTimer: number = -1
  private summaryHideTimer: number = -1

  aboutToAppear(): void {
    this.categoryName = NavParams.categoryName
    this.selectedBrands = NavParams.selectedBrands
    this.selectedPriceLabel = NavParams.selectedPriceLabel
    this.selectedOtherLabels = NavParams.selectedOtherLabels

    this.loadData()
  }

  aboutToDisappear(): void {
    if (this.summaryTimer !== -1) {
      clearTimeout(this.summaryTimer)
      this.summaryTimer = -1
    }

    if (this.summaryHideTimer !== -1) {
      clearTimeout(this.summaryHideTimer)
      this.summaryHideTimer = -1
    }
  }

  async loadData(): Promise<void> {
    this.isLoading = true

    await DataProvider.getProductRepository().loadFilteredProducts(
      this.categoryName, this.selectedBrands, this.sortType
    )

    let allProducts: Product[] = DataProvider.getProductRepository().getProducts()
    let filtered: Product[] = []
    let i: number = 0

    while (i < allProducts.length) {
      let product: Product = allProducts[i]

      if (
        this.categoryName.length > 0 &&
        product.category !== this.categoryName
      ) {
        i = i + 1
        continue
      }

      if (
        this.selectedBrands.length > 0 &&
        !this.matchesBrand(product.brand)
      ) {
        i = i + 1
        continue
      }

      if (
        this.selectedPriceLabel.length > 0 &&
        !this.matchesPriceRange(product.lowestPrice)
      ) {
        i = i + 1
        continue
      }

      if (this.selectedOtherLabels.length > 0) {
        i = i + 1
        continue
      }

      filtered.push(product)
      i = i + 1
    }

    this.allFilteredProducts = filtered
    this.applySort()
    this.isLoading = false

    this.summaryHeight = 46
    this.summaryOpacity = 1
    this.summaryBottomMargin = 0
    this.showSummaryBanner = true
    this.showSortExpanded = true

    if (this.summaryTimer !== -1) {
      clearTimeout(this.summaryTimer)
      this.summaryTimer = -1
    }

    if (this.summaryHideTimer !== -1) {
      clearTimeout(this.summaryHideTimer)
      this.summaryHideTimer = -1
    }

    this.summaryTimer = setTimeout(() => {
      animateTo({
        duration: 450,
        curve: Curve.EaseInOut
      }, () => {
        this.summaryHeight = 0
        this.summaryOpacity = 0
        this.summaryBottomMargin = 0
      })

      this.summaryTimer = -1
    }, 1800)

    this.summaryHideTimer = setTimeout(() => {
      this.showSummaryBanner = false
      this.summaryHideTimer = -1
    }, 2300)

    setTimeout(() => {
      this.showSortExpanded = false
    }, 3000)
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
    } else if (this.sortType === 'pricePriority') {
      sorted.sort(
        (a: Product, b: Product): number => {
          return a.lowestPrice - b.lowestPrice
        }
      )
    } else if (this.sortType === 'ratingPriority') {
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

  getCurrentSortLabel(): string {
    if (this.sortType === 'pricePriority') {
      return '价格优先'
    }

    if (this.sortType === 'ratingPriority') {
      return '评分优先'
    }

    return '综合推荐'
  }

  getCurrentSortColor(): string {
    if (this.sortType === 'pricePriority') {
      return '#FF3B30'
    }

    if (this.sortType === 'ratingPriority') {
      return '#2D8A4E'
    }

    return '#5267E8'
  }

  getCurrentSortBackground(): string {
    if (this.sortType === 'pricePriority') {
      return '#FFF1F0'
    }

    if (this.sortType === 'ratingPriority') {
      return '#EEF9F1'
    }

    return '#EEF1FF'
  }

  toggleSortExpanded(): void {
    this.showSortExpanded = !this.showSortExpanded
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
  buildSummaryPanel(): void {
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
    }
    .width('100%')
    .height(this.summaryHeight)
    .opacity(this.summaryOpacity)
    .padding({
      left: 16,
      right: 16,
      top: 14,
      bottom: 10
    })
    .margin({
      bottom: this.summaryBottomMargin
    })
    .backgroundColor('#F5F6F8')
    .clip(true)
  }

  @Builder
  buildSortPanel(): void {
    if (this.showSortExpanded) {
      Column() {
        Row() {
          Text('排序')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1C1E')
            .layoutWeight(1)

          Text('收起')
            .fontSize(12)
            .fontColor('#5267E8')
            .onClick(() => {
              this.toggleSortExpanded()
            })
        }
        .width('100%')
        .margin({ bottom: 10 })

        Row({ space: 8 }) {
          this.buildSortTabItem(
            'recommend',
            '综合推荐'
          )

          this.buildSortTabItem(
            'pricePriority',
            '价格优先'
          )

          this.buildSortTabItem(
            'ratingPriority',
            '评分优先'
          )
        }
        .width('100%')
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 8,
        bottom: 12
      })
      .backgroundColor('#F5F6F8')
    } else {
      Row() {
        Text('排序')
          .fontSize(12)
          .fontColor('#8E8E93')

        Text(this.getCurrentSortLabel())
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getCurrentSortColor())
          .padding({
            left: 10,
            right: 10,
            top: 5,
            bottom: 5
          })
          .backgroundColor(
            this.getCurrentSortBackground()
          )
          .borderRadius(8)
          .margin({ left: 8 })

        Blank()

        Text('展开')
          .fontSize(12)
          .fontColor('#5267E8')
      }
      .width('100%')
      .padding({
        left: 14,
        right: 14,
        top: 8,
        bottom: 8
      })
      .margin({
        left: 16,
        right: 16,
        bottom: 10
      })
      .backgroundColor(Color.White)
      .border({
        width: 1,
        color: '#E8EAF0'
      })
      .borderRadius(12)
      .onClick(() => {
        this.toggleSortExpanded()
      })
    }
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

      Button('只看低价')
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
        if (this.showSummaryBanner) {
          this.buildSummaryPanel()
        }

        this.buildSortPanel()

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
