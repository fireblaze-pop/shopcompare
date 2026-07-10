import { NavRouter } from '../utils/NavRouter'
import { Product } from '../models/DataModels'
import { DataProvider } from '../data/DataProvider'
import { NavParams } from '../utils/PreferenceManager'
import { FilterResultCard } from '../components/filter/FilterResultCard'
import { ProductFilterParams } from '../data/repository/ProductRepository'

@Entry
@Component
export struct CompareResultPage {
  @State products: Product[] = []
  @State allFilteredProducts: Product[] = []
  @State sortType: string = 'recommend'
  @State isLoading: boolean = true
  @State categoryName: string = ''
  @State selectedBrands: string = ''
  @State selectedPriceLabel: string = ''
  @State selectedMinPrice: number = 0
  @State selectedMaxPrice: number = 0
  @State selectedOtherLabels: string = ''
  @State summaryHeight: number = 46
  @State summaryOpacity: number = 1
  @State summaryBottomMargin: number = 0
  @State showSummaryBanner: boolean = true
  @State showSortExpanded: boolean = true
  @State compareMode: boolean = false
  @State selectedCompareIds: string[] = []

  private summaryTimer: number = -1
  private summaryHideTimer: number = -1
  private loadRequestSeq: number = 0

  aboutToAppear(): void {
    this.categoryName = NavParams.categoryName
    this.selectedBrands = NavParams.selectedBrands
    this.selectedPriceLabel = NavParams.selectedPriceLabel
    this.selectedMinPrice = NavParams.selectedMinPrice
    this.selectedMaxPrice = NavParams.selectedMaxPrice
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
    await this.fetchFilteredProducts(true)
  }

  async reloadForSort(): Promise<void> {
    await this.fetchFilteredProducts(false)
  }

  async fetchFilteredProducts(
    resetPanels: boolean
  ): Promise<void> {
    this.loadRequestSeq = this.loadRequestSeq + 1
    let requestSeq: number = this.loadRequestSeq
    this.isLoading = true

    let params: ProductFilterParams =
      this.buildFilterParams()

    let filtered: Product[] =
      await DataProvider
        .getProductRepository()
        .loadFilteredProductsByParams(params)

    if (requestSeq !== this.loadRequestSeq) {
      return
    }

    this.allFilteredProducts = filtered
    this.products = filtered
    this.isLoading = false

    if (resetPanels) {
      this.startEntryPanels()
    }
  }

  buildFilterParams(): ProductFilterParams {
    return {
      category: this.categoryName,
      brands: this.parseCommaList(this.selectedBrands),
      minPrice: this.selectedMinPrice,
      maxPrice: this.selectedMaxPrice,
      sort: this.getApiSortValue()
    }
  }

  getApiSortValue(): string {
    if (this.sortType === 'pricePriority') {
      return 'price_low'
    }

    if (this.sortType === 'ratingPriority') {
      return 'rating'
    }

    return 'recommend'
  }

  startEntryPanels(): void {
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

  changeSort(type: string): void {
    if (this.sortType === type) {
      return
    }

    this.sortType = type
    this.reloadForSort()
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
    let maxCount: number = 0
    let i: number = 0

    while (i < this.products.length) {
      if (this.products[i].platformCount > maxCount) {
        maxCount = this.products[i].platformCount
      }
      i = i + 1
    }

    return maxCount
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

    NavRouter.push('ProductDetailPage')
  }

  navigateBackToFilter(): void {
          NavRouter.back()
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
        NavRouter.back()
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
        ' 件商品 · 单品最多覆盖 ' +
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
  buildCompareModeBanner(): void {
    Row() {
      Column({ space: 3 }) {
        Text('选择要对比的商品')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Text('点击商品卡片加入或移出对比，最多选择 4 款')
          .fontSize(11)
          .fontColor('#6E7178')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(
        this.selectedCompareIds.length.toString() +
        ' / 4'
      )
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5267E8')
        .padding({
          left: 10,
          right: 10,
          top: 6,
          bottom: 6
        })
        .backgroundColor('#EEF1FF')
        .borderRadius(9)
    }
    .width('100%')
    .padding({
      left: 14,
      right: 14,
      top: 12,
      bottom: 12
    })
    .margin({
      left: 16,
      right: 16,
      bottom: 10
    })
    .backgroundColor(Color.White)
    .borderRadius(14)
    .border({
      width: 1,
      color: '#DDE2FF'
    })
    .alignItems(VerticalAlign.Center)
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
    NavRouter.back()
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

  isCompareSelected(productId: string): boolean {
    return this.selectedCompareIds.indexOf(productId) >= 0
  }

  enterCompareMode(): void {
    this.compareMode = true
    this.selectedCompareIds = []
  }

  cancelCompareMode(): void {
    this.compareMode = false
    this.selectedCompareIds = []
  }

  toggleCompareProduct(product: Product): void {
    let selectedIndex: number =
      this.selectedCompareIds.indexOf(product.id)
    let nextIds: string[] = []
    let i: number = 0

    if (selectedIndex >= 0) {
      while (i < this.selectedCompareIds.length) {
        if (i !== selectedIndex) {
          nextIds.push(this.selectedCompareIds[i])
        }
        i = i + 1
      }

      this.selectedCompareIds = nextIds
      return
    }

    if (this.selectedCompareIds.length >= 4) {
      return
    }

    while (i < this.selectedCompareIds.length) {
      nextIds.push(this.selectedCompareIds[i])
      i = i + 1
    }

    nextIds.push(product.id)
    this.selectedCompareIds = nextIds
  }

  buildProductIdList(ids: string[]): string {
    let result: string = ''
    let i: number = 0

    while (i < ids.length) {
      if (result.length > 0) {
        result = result + ','
      }

      result = result + ids[i]
      i = i + 1
    }

    return result
  }

  startCompare(): void {
    if (this.selectedCompareIds.length < 2) {
      return
    }

    NavParams.compareProductIds =
      this.buildProductIdList(this.selectedCompareIds)

    NavRouter.push('CompareTablePage')
  }

  @Builder
  buildBottomActions(): void {
    if (this.compareMode) {
      Row() {
        Column({ space: 3 }) {
          Text(
            '已选 ' +
            this.selectedCompareIds.length.toString() +
            ' / 4'
          )
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text('至少选择 2 款，最多 4 款')
            .fontSize(11)
            .fontColor('#8E8E93')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('取消')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5E6168')
          .backgroundColor('#F5F6F8')
          .borderRadius(12)
          .height(44)
          .padding({
            left: 16,
            right: 16
          })
          .margin({ right: 8 })
          .onClick(() => {
            this.cancelCompareMode()
          })

        Button('开始对比')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor(
            this.selectedCompareIds.length >= 2 ?
            '#5267E8' :
            '#B8C0F3'
          )
          .borderRadius(12)
          .height(44)
          .padding({
            left: 18,
            right: 18
          })
          .onClick(() => {
            this.startCompare()
          })
      }
      .width('100%')
      .height(74)
      .padding({
        left: 16,
        right: 16,
        top: 10,
        bottom: 10
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
    } else {
      Row({ space: 12 }) {
        Button('选择商品对比')
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
            this.enterCompareMode()
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

        if (this.compareMode) {
          this.buildCompareModeBanner()
        }

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
                  compareMode: this.compareMode,
                  isCompareSelected:
                    this.isCompareSelected(product.id),
                  onProductAction: (
                    selected: Product
                  ): void => {
                    this.navigateToDetail(selected)
                  },
                  onCompareAction: (
                    selected: Product
                  ): void => {
                    this.toggleCompareProduct(selected)
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
