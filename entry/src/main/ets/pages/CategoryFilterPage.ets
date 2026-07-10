import { NavRouter } from '../utils/NavRouter'
import {
  FilterGroup,
  FilterOption
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

interface PriceBounds {
  min: number
  max: number
}

interface ProductCountResponse {
  total: number
}

@Entry
@Component
export struct CategoryFilterPage {
  @State categoryName: string = ''
  @State categoryId: string = ''
  @State filterGroups: FilterGroup[] = []
  @State selectedIds: string[] = []
  @State isLoading: boolean = false
  @State matchedProductCount: number = 0
  @State isCountLoading: boolean = false
  @State activeCountPath: string = ''

  private http: HttpClient = DataProvider.getHttpClient()

  aboutToAppear(): void {
    this.categoryName = NavParams.categoryName
    this.categoryId = NavParams.categoryId
    this.loadFilters()
  }

  async loadFilters(): Promise<void> {
    let localGroups: FilterGroup[] =
      MockData.getFilterGroups(this.categoryId)

    this.isLoading = true
    this.isCountLoading = true

    try {
      let resp = await this.http.get(
        '/filters?category=' +
        encodeURIComponent(this.categoryName)
      )

      if (resp.statusCode === 200) {
        let data: FiltersResponse = JSON.parse(resp.data)

        this.filterGroups =
          this.buildFilterGroups(data, localGroups)
        this.matchedProductCount = data.product_count
        this.isCountLoading = false
        this.isLoading = false
        return
      }
    } catch (e) {
    }

    this.filterGroups =
      this.getSupportedLocalGroups(localGroups)
    this.isLoading = false
    await this.refreshMatchedProductCount()
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

    return groups
  }

  getSupportedLocalGroups(
    localGroups: FilterGroup[]
  ): FilterGroup[] {
    let groups: FilterGroup[] = []
    this.appendLocalGroupByType(groups, localGroups, 'brand')
    this.appendLocalGroupByType(groups, localGroups, 'price')
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
    this.refreshMatchedProductCountByIds(newIds)
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
    let emptyIds: string[] = []
    this.selectedIds = emptyIds
    this.refreshMatchedProductCountByIds(emptyIds)
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

    let priceBounds: PriceBounds =
      this.getPriceBoundsByLabel(selectedPriceLabel)

    NavParams.categoryId = this.categoryId
    NavParams.categoryName = this.categoryName
    NavParams.selectedBrands = selectedBrands
    NavParams.selectedPriceLabel = selectedPriceLabel
    NavParams.selectedMinPrice = priceBounds.min
    NavParams.selectedMaxPrice = priceBounds.max
    NavParams.selectedOtherLabels = selectedOtherLabels
    NavParams.compareProductIds = ''

    NavRouter.push('CompareResultPage')
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

  async refreshMatchedProductCount(): Promise<void> {
    let selectedIdsSnapshot: string[] =
      this.copyStringArray(this.selectedIds)

    await this.refreshMatchedProductCountByIds(
      selectedIdsSnapshot
    )
  }

  async refreshMatchedProductCountByIds(
    selectedIds: string[]
  ): Promise<void> {
    let path: string =
      this.buildCountPathBySelectedIds(selectedIds)

    this.activeCountPath = path
    this.isCountLoading = true

    let response = await this.http.get(path)

    if (path !== this.activeCountPath) {
      return
    }

    if (response.statusCode === 200) {
      let data: ProductCountResponse =
        JSON.parse(response.data)

      this.matchedProductCount = data.total
    } else {
      this.matchedProductCount = 0
    }

    this.isCountLoading = false
  }

  buildCountPathBySelectedIds(
    selectedIds: string[]
  ): string {
    let path: string = '/products?page=1&size=1'

    if (this.categoryName.length > 0) {
      path = path +
        '&category=' +
        encodeURIComponent(this.categoryName)
    }

    let brands: string[] =
      this.getSelectedLabelsByTypeFromIds(
        selectedIds,
        'brand'
      )

    if (brands.length > 0) {
      path = path +
        '&brand=' +
        encodeURIComponent(brands.join(','))
    }

    let priceBounds: PriceBounds =
      this.getSelectedPriceBoundsFromIds(selectedIds)

    if (priceBounds.min > 0) {
      path = path +
        '&min_price=' +
        priceBounds.min.toString()
    }

    if (priceBounds.max > 0) {
      path = path +
        '&max_price=' +
        priceBounds.max.toString()
    }

    path = path + '&sort=recommend'
    return path
  }

  getSelectedPriceBounds(): PriceBounds {
    return this.getSelectedPriceBoundsFromIds(
      this.selectedIds
    )
  }

  getSelectedPriceBoundsFromIds(
    selectedIds: string[]
  ): PriceBounds {
    let labels: string[] =
      this.getSelectedLabelsByTypeFromIds(
        selectedIds,
        'price'
      )

    if (labels.length === 0) {
      return { min: 0, max: 0 }
    }

    return this.getPriceBoundsByLabel(labels[0])
  }

  getPriceBoundsByLabel(
    label: string
  ): PriceBounds {
    if (label.length === 0) {
      return { min: 0, max: 0 }
    }

    let belowIndex: number = label.indexOf('以下')
    if (belowIndex >= 0) {
      return {
        min: 0,
        max: Number(label.substring(0, belowIndex))
      }
    }

    let aboveIndex: number = label.indexOf('以上')
    if (aboveIndex >= 0) {
      return {
        min: Number(label.substring(0, aboveIndex)),
        max: 0
      }
    }

    let dashIndex: number = label.indexOf('-')
    if (dashIndex >= 0) {
      return {
        min: Number(label.substring(0, dashIndex)),
        max: Number(label.substring(dashIndex + 1))
      }
    }

    return { min: 0, max: 0 }
  }

  getSelectedLabelsByType(
    groupType: string
  ): string[] {
    return this.getSelectedLabelsByTypeFromIds(
      this.selectedIds,
      groupType
    )
  }

  getSelectedLabelsByTypeFromIds(
    selectedIds: string[],
    groupType: string
  ): string[] {
    let labels: string[] = []
    let i: number = 0

    while (i < selectedIds.length) {
      let option: FilterOption | undefined =
        this.findOptionById(selectedIds[i])

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

  copyStringArray(source: string[]): string[] {
    let result: string[] = []
    let i: number = 0

    while (i < source.length) {
      result.push(source[i])
      i = i + 1
    }

    return result
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
          NavRouter.back()
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
          this.isCountLoading ?
          '正在计算...' :
          '查看 ' +
          this.matchedProductCount.toString() +
          ' 件商品'
        )
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#5267E8')
          .borderRadius(14)
          .height(48)
          .layoutWeight(1)
          .enabled(!this.isCountLoading)
          .opacity(this.isCountLoading ? 0.72 : 1)
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
