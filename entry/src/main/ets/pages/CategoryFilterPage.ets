import { router } from '@kit.ArkUI'
import {
  FilterGroup,
  FilterOption,
  Product
} from '../models/DataModels'
import { MockData } from '../data/MockData'
import { NavParams } from '../utils/PreferenceManager'
import { DataProvider } from '../data/DataProvider'
import { HttpClient } from '../utils/HttpClient'
import { FilterGroupCard } from '../components/filter/FilterGroupCard'

interface BrandItem {
  name: string
  count: number
}

interface PriceBin {
  label: string
  min: number
  max: number
  count: number
}

interface FiltersResponse {
  category: string
  brands: BrandItem[]
  price_bins: PriceBin[]
  product_count: number
}

@Entry
@Component
struct CategoryFilterPage {
  @State categoryName: string = ''
  @State categoryId: string = ''
  @State filterGroups: FilterGroup[] = []
  @State selectedIds: string[] = []
  @State isLoading: boolean = false

  private http: HttpClient = DataProvider.getHttpClient()

  aboutToAppear(): void {
    this.categoryName = NavParams.categoryName
    this.categoryId = NavParams.categoryId
    this.loadFilters()
  }

  async loadFilters(): Promise<void> {
    let localGroups: FilterGroup[] =
      MockData.getFilterGroups(this.categoryId)

    this.filterGroups = localGroups
    this.isLoading = true

    try {
      let resp = await this.http.get(
        '/filters?category=' + encodeURIComponent(this.categoryName)
      )

      if (
        resp.statusCode === 200 &&
        this.selectedIds.length === 0
      ) {
        let data: FiltersResponse = JSON.parse(resp.data)

        this.filterGroups =
          this.buildFilterGroups(data, localGroups)
      }
    } catch (e) {
    }

    this.isLoading = false
  }

  buildFilterGroups(
    data: FiltersResponse,
    localGroups: FilterGroup[]
  ): FilterGroup[] {
    let groups: FilterGroup[] = []

    if (data.brands.length > 0) {
      let brandOptions: FilterOption[] = []
      let i: number = 0

      while (i < data.brands.length) {
        brandOptions.push({
          id: 'brand_remote_' + i.toString(),
          label: data.brands[i].name,
          selected: false
        })
        i = i + 1
      }

      groups.push({
        name: '品牌',
        type: 'brand',
        options: brandOptions
      })
    } else {
      this.appendLocalGroupByType(groups, localGroups, 'brand')
    }

    let priceGroup: FilterGroup =
      this.buildRemotePriceGroup(data)

    if (priceGroup.options.length > 0) {
      groups.push(priceGroup)
    } else {
      this.appendLocalGroupByType(groups, localGroups, 'price')
    }

    let j: number = 0

    while (j < localGroups.length) {
      if (
        localGroups[j].type !== 'brand' &&
        localGroups[j].type !== 'price'
      ) {
        groups.push(localGroups[j])
      }

      j = j + 1
    }

    return groups
  }

  buildRemotePriceGroup(
    data: FiltersResponse
  ): FilterGroup {
    let options: FilterOption[] = []

    if (data.price_bins.length === 0) {
      return {
        name: '价格区间',
        type: 'price',
        options: options
      }
    }

    let i: number = 0
    while (i < data.price_bins.length) {
      options.push({
        id: 'price_remote_' + i.toString(),
        label: data.price_bins[i].label,
        selected: false
      })
      i = i + 1
    }

    return {
      name: '价格区间',
      type: 'price',
      options: options
    }
  }

  appendLocalGroupByType(
    target: FilterGroup[],
    source: FilterGroup[],
    groupType: string
  ): void {
    let i: number = 0

    while (i < source.length) {
      if (source[i].type === groupType) {
        target.push(source[i])
        return
      }

      i = i + 1
    }
  }

  toggleOption(optionId: string): void {
    let currentGroup: FilterGroup | undefined =
      this.findGroupByOptionId(optionId)

    let newIds: string[] = []
    let found: boolean = false
    let i: number = 0

    while (i < this.selectedIds.length) {
      let currentId: string = this.selectedIds[i]

      if (currentId === optionId) {
        found = true
      } else if (
        currentGroup !== undefined &&
        currentGroup.type === 'price' &&
        this.isOptionInGroup(currentId, currentGroup)
      ) {
      } else {
        newIds.push(currentId)
      }

      i = i + 1
    }

    if (!found) {
      newIds.push(optionId)
    }

    this.selectedIds = newIds
  }

  isOptionInGroup(
    optionId: string,
    group: FilterGroup
  ): boolean {
    let i: number = 0

    while (i < group.options.length) {
      if (group.options[i].id === optionId) {
        return true
      }

      i = i + 1
    }

    return false
  }

  findGroupByOptionId(
    optionId: string
  ): FilterGroup | undefined {
    let i: number = 0

    while (i < this.filterGroups.length) {
      let group: FilterGroup = this.filterGroups[i]
      let j: number = 0

      while (j < group.options.length) {
        if (group.options[j].id === optionId) {
          return group
        }

        j = j + 1
      }

      i = i + 1
    }

    return undefined
  }

  resetFilters(): void {
    this.selectedIds = []
  }

  confirmFilters(): void {
    let selectedBrands: string = ''
    let selectedPriceLabel: string = ''
    let selectedOtherLabels: string = ''
    let i: number = 0

    while (i < this.selectedIds.length) {
      let option: FilterOption | undefined =
        this.findOptionById(this.selectedIds[i])

      if (option !== undefined) {
        let group: FilterGroup | undefined =
          this.findGroupByOptionId(option.id)

        if (group !== undefined) {
          if (group.type === 'brand') {
            selectedBrands =
              this.appendCommaValue(
                selectedBrands,
                option.label
              )
          } else if (group.type === 'price') {
            selectedPriceLabel = option.label
          } else {
            selectedOtherLabels =
              this.appendCommaValue(
                selectedOtherLabels,
                option.label
              )
          }
        }
      }

      i = i + 1
    }

    NavParams.categoryId = this.categoryId
    NavParams.categoryName = this.categoryName
    NavParams.selectedBrands = selectedBrands
    NavParams.selectedPriceLabel = selectedPriceLabel
    NavParams.selectedOtherLabels = selectedOtherLabels

    router.pushUrl({
      url: 'pages/CompareResultPage'
    })
  }

  appendCommaValue(
    source: string,
    value: string
  ): string {
    if (source.length === 0) {
      return value
    }

    return source + ',' + value
  }

  findOptionById(
    id: string
  ): FilterOption | undefined {
    let i: number = 0

    while (i < this.filterGroups.length) {
      let group: FilterGroup = this.filterGroups[i]
      let j: number = 0

      while (j < group.options.length) {
        if (group.options[j].id === id) {
          return group.options[j]
        }

        j = j + 1
      }

      i = i + 1
    }

    return undefined
  }

  getMatchedProductCount(): number {
    let products: Product[] = MockData.getProducts()
    let count: number = 0
    let i: number = 0

    while (i < products.length) {
      let product: Product = products[i]

      if (
        product.category === this.categoryName &&
        this.matchesSelectedBrand(product) &&
        this.matchesSelectedPrice(product.lowestPrice)
      ) {
        count = count + 1
      }

      i = i + 1
    }

    return count
  }

  matchesSelectedBrand(
    product: Product
  ): boolean {
    let selectedBrands: string[] =
      this.getSelectedLabelsByType('brand')

    if (selectedBrands.length === 0) {
      return true
    }

    return selectedBrands.indexOf(product.brand) >= 0
  }

  matchesSelectedPrice(
    price: number
  ): boolean {
    let priceLabels: string[] =
      this.getSelectedLabelsByType('price')

    if (priceLabels.length === 0) {
      return true
    }

    return this.matchesPriceLabel(
      price,
      priceLabels[0]
    )
  }

  getSelectedLabelsByType(
    groupType: string
  ): string[] {
    let labels: string[] = []
    let i: number = 0

    while (i < this.selectedIds.length) {
      let option: FilterOption | undefined =
        this.findOptionById(this.selectedIds[i])

      if (option !== undefined) {
        let group: FilterGroup | undefined =
          this.findGroupByOptionId(option.id)

        if (
          group !== undefined &&
          group.type === groupType
        ) {
          labels.push(option.label)
        }
      }

      i = i + 1
    }

    return labels
  }

  matchesPriceLabel(
    price: number,
    label: string
  ): boolean {
    let belowIndex: number = label.indexOf('以下')

    if (belowIndex >= 0) {
      return price <= Number(
        label.substring(0, belowIndex)
      )
    }

    let aboveIndex: number = label.indexOf('以上')

    if (aboveIndex >= 0) {
      return price >= Number(
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
        price >= minValue &&
        price <= maxValue
      )
    }

    return true
  }

  build() {
    Column() {
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

        Text(this.categoryName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .layoutWeight(1)

        if (this.isLoading) {
          Text('更新中')
            .fontSize(11)
            .fontColor('#5267E8')
            .padding({
              left: 9,
              right: 9,
              top: 5,
              bottom: 5
            })
            .backgroundColor('#EEF1FF')
            .borderRadius(8)
        }
      }
      .width('100%')
      .height(64)
      .padding({
        left: 8,
        right: 16
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      List({ space: 12 }) {
        ListItem() {
          Text('筛选条件')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .width('100%')
            .padding({
              left: 2,
              bottom: 2
            })
        }

        ForEach(
          this.filterGroups,
          (
            group: FilterGroup,
            groupIndex: number
          ) => {
            ListItem() {
              FilterGroupCard({
                group: group,
                selectedIds: this.selectedIds,
                onFilterOptionAction: (
                  optionId: string
                ): void => {
                  this.toggleOption(optionId)
                }
              })
            }
          },
          (
            group: FilterGroup,
            groupIndex: number
          ) => group.type + groupIndex.toString()
        )
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: 16,
        right: 16,
        top: 16,
        bottom: 18
      })
      .backgroundColor('#F5F6F8')
      .scrollBar(BarState.Off)

      Row({ space: 12 }) {
        Button('重置')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5267E8')
          .backgroundColor(Color.White)
          .borderRadius(14)
          .border({
            width: 1,
            color: '#5267E8'
          })
          .width(100)
          .height(48)
          .onClick(() => {
            this.resetFilters()
          })

        Button(
          '查看 ' +
          this.getMatchedProductCount().toString() +
          ' 件商品'
        )
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#5267E8')
          .borderRadius(14)
          .height(48)
          .layoutWeight(1)
          .onClick(() => {
            this.confirmFilters()
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
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
