import { router } from '@kit.ArkUI';
import { FilterGroup, FilterOption } from '../models/DataModels';
import { MockData } from '../data/MockData';
import { NavParams } from '../utils/PreferenceManager';
import { DataProvider } from '../data/DataProvider';
import { HttpClient } from '../utils/HttpClient';

interface FiltersResponse {
  category: string
  brands: string[]
  price_range: PriceRange
  product_count: number
}

interface PriceRange {
  min: number
  max: number
}

@Entry
@Component
struct CategoryFilterPage {
  @State categoryName: string = '';
  @State categoryId: string = '';
  @State filterGroups: FilterGroup[] = [];
  @State selectedIds: string[] = [];
  @State isLoading: boolean = true;
  private http: HttpClient = DataProvider.getHttpClient()

  aboutToAppear(): void {
    this.categoryName = NavParams.categoryName;
    this.categoryId = NavParams.categoryId;
    this.loadFilters();
  }

  async loadFilters(): Promise<void> {
    this.isLoading = true
    try {
      let resp = await this.http.get('/filters?category=' + this.categoryName)
      if (resp.statusCode === 200) {
        let data: FiltersResponse = JSON.parse(resp.data) as FiltersResponse
        this.filterGroups = this.buildFilterGroups(data)
        this.isLoading = false
        return
      }
    } catch (e) {
    }
    this.filterGroups = MockData.getFilterGroups(this.categoryId)
    this.isLoading = false
  }

  buildFilterGroups(data: FiltersResponse): FilterGroup[] {
    let groups: FilterGroup[] = []
    if (data.brands.length > 0) {
      let brandOptions: FilterOption[] = []
      let i: number = 0
      while (i < data.brands.length) {
        let option: FilterOption = { id: 'brand_' + data.brands[i], label: data.brands[i], selected: false }
        brandOptions.push(option)
        i = i + 1
      }
      let brandGroup: FilterGroup = { name: '品牌', type: 'brand', options: brandOptions }
      groups.push(brandGroup)
    }
    let min: number = data.price_range.min
    let max: number = data.price_range.max
    let step: number = Math.max(1, Math.floor((max - min) / 4))
    let priceOptions: FilterOption[] = []
    let p: number = min
    while (p < max) {
      let next: number = p + step
      if (next >= max) {
        next = max
      }
      let label: string = p.toString() + '-' + next.toString()
      let option: FilterOption = { id: 'price_' + label, label: label, selected: false }
      priceOptions.push(option)
      p = next
      if (p >= max) {
        break
      }
    }
    let extraOption: FilterOption = { id: 'price_above_' + max.toString(), label: max.toString() + '以上', selected: false }
    priceOptions.push(extraOption)
    let priceGroup: FilterGroup = { name: '价格区间', type: 'price', options: priceOptions }
    groups.push(priceGroup)
    return groups
  }

  isSelected(optionId: string): boolean {
    return this.selectedIds.indexOf(optionId) >= 0;
  }

  toggleOption(optionId: string): void {
    let newIds: string[] = [];
    let found: boolean = false;
    let i: number = 0;
    while (i < this.selectedIds.length) {
      if (this.selectedIds[i] === optionId) {
        found = true;
      } else {
        newIds.push(this.selectedIds[i]);
      }
      i = i + 1;
    }
    if (!found) {
      newIds.push(optionId);
    }
    this.selectedIds = newIds;
  }

  getOptionDisplayLabel(group: FilterGroup, option: FilterOption): string {
    if (group.type === 'price') {
      return '\u00A5' + option.label;
    }
    return option.label;
  }

  @Builder
  buildChip(option: FilterOption): void {
    Text(this.getOptionDisplayLabel(this.getCurrentGroup(option), option))
      .fontSize(14)
      .fontColor(this.isSelected(option.id) ? '#FFFFFF' : '#3C3C3C')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.isSelected(option.id) ? '#007AFF' : '#F2F2F7')
      .borderRadius(20)
      .margin({ right: 10, bottom: 10 })
      .onClick(() => {
        this.toggleOption(option.id);
      })
  }

  getCurrentGroup(option: FilterOption): FilterGroup {
    let i: number = 0;
    while (i < this.filterGroups.length) {
      let group: FilterGroup = this.filterGroups[i];
      let j: number = 0;
      while (j < group.options.length) {
        if (group.options[j].id === option.id) {
          return group;
        }
        j = j + 1;
      }
      i = i + 1;
    }
    return this.filterGroups[0];
  }

  resetFilters(): void {
    this.selectedIds = [];
  }

  confirmFilters(): void {
    let selectedBrands: string = '';
    let selectedPriceLabel: string = '';
    let selectedOtherLabels: string = '';
    let i: number = 0;
    while (i < this.selectedIds.length) {
      let option: FilterOption | undefined = this.findOptionById(this.selectedIds[i]);
      if (option !== undefined) {
        let group: FilterGroup = this.getCurrentGroup(option);
        if (group.type === 'brand') {
          if (selectedBrands.length > 0) {
            selectedBrands = selectedBrands + ',' + option.label;
          } else {
            selectedBrands = option.label;
          }
        } else if (group.type === 'price') {
          selectedPriceLabel = option.label;
        } else {
          if (selectedOtherLabels.length > 0) {
            selectedOtherLabels = selectedOtherLabels + ',' + option.label;
          } else {
            selectedOtherLabels = option.label;
          }
        }
      }
      i = i + 1;
    }
    NavParams.categoryId = this.categoryId;
    NavParams.categoryName = this.categoryName;
    NavParams.selectedBrands = selectedBrands;
    NavParams.selectedPriceLabel = selectedPriceLabel;
    NavParams.selectedOtherLabels = selectedOtherLabels;
    router.pushUrl({
      url: 'pages/CompareResultPage'
    });
  }

  findOptionById(id: string): FilterOption | undefined {
    let i: number = 0;
    while (i < this.filterGroups.length) {
      let group: FilterGroup = this.filterGroups[i];
      let j: number = 0;
      while (j < group.options.length) {
        if (group.options[j].id === id) {
          return group.options[j];
        }
        j = j + 1;
      }
      i = i + 1;
    }
    return undefined;
  }

  getSelectedCount(): number {
    return this.selectedIds.length;
  }

  build() {
    Column() {
      Row() {
        Text('\u2190')
          .fontSize(24)
          .fontColor('#1C1C1E')
          .padding({ right: 12 })
          .onClick(() => {
            router.back();
          })
        Text(this.categoryName)
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#1C1C1E')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          ForEach(this.filterGroups, (group: FilterGroup, groupIndex: number) => {
            Column() {
              Text(group.name)
                .fontSize(18)
                .fontWeight(600)
                .fontColor('#1C1C1E')
                .padding({ left: 16, top: 20, bottom: 8 })
                .width('100%')

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(group.options, (option: FilterOption, optionIndex: number) => {
                  this.buildChip(option)
                })
              }
              .padding({ left: 16, right: 16 })
              .width('100%')
            }
            .width('100%')
          })
        }
        .width('100%')
        .padding({ bottom: 80 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F2F2F7')
      .scrollBar(BarState.Off)

      Row() {
        Button('重置')
          .fontSize(16)
          .fontColor('#007AFF')
          .backgroundColor('#FFFFFF')
          .borderRadius(24)
          .borderWidth(1)
          .borderColor('#007AFF')
          .width(100)
          .height(44)
          .onClick(() => {
            this.resetFilters();
          })

        Blank().width(12)

        Button('确认筛选' + '(' + this.getSelectedCount().toString() + ')')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007AFF')
          .borderRadius(24)
          .height(44)
          .layoutWeight(1)
          .onClick(() => {
            this.confirmFilters();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')
      .height(64)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}
