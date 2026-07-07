import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { Product, PlatformListing } from '../models/DataModels';
import { MockData } from '../data/MockData';
import { NavParams } from '../utils/PreferenceManager';
import { formatPrice } from '../utils/FormatUtils';

@Entry
@Component
struct CompareResultPage {
  @State products: Product[] = [];
  @State allFilteredProducts: Product[] = [];
  @State sortType: string = 'recommend';
  @State isLoading: boolean = true;
  @State currentPage: number = 1;
  @State categoryName: string = '';
  @State selectedBrands: string = '';
  @State selectedPriceLabel: string = '';
  @State selectedOtherLabels: string = '';

  aboutToAppear(): void {
    this.categoryName = NavParams.categoryName;
    this.selectedBrands = NavParams.selectedBrands;
    this.selectedPriceLabel = NavParams.selectedPriceLabel;
    this.selectedOtherLabels = NavParams.selectedOtherLabels;
    let categoryId: string = NavParams.categoryId;
    this.loadData(categoryId);
  }

  loadData(categoryId: string): void {
    this.isLoading = true;
    setTimeout(() => {
      let allProducts: Product[] = MockData.getProducts();
      let categoryField: string = '';
      if (categoryId.length > 4) {
        categoryField = categoryId.substring(4);
      }
      let filtered: Product[] = [];
      let i: number = 0;
      while (i < allProducts.length) {
        let product: Product = allProducts[i];
        let matches: boolean = true;
        if (categoryField.length > 0) {
          if (product.category !== categoryField) {
            matches = false;
          }
        }
        if (matches && this.selectedBrands.length > 0) {
          if (!this.matchesBrand(product.brand)) {
            matches = false;
          }
        }
        if (matches && this.selectedPriceLabel.length > 0) {
          if (!this.matchesPriceRange(product.lowestPrice)) {
            matches = false;
          }
        }
        if (matches) {
          filtered.push(product);
        }
        i = i + 1;
      }
      this.allFilteredProducts = filtered;
      this.applySort();
      this.isLoading = false;
    }, 800);
  }

  matchesBrand(brand: string): boolean {
    let brands: string[] = this.parseCommaList(this.selectedBrands);
    let i: number = 0;
    while (i < brands.length) {
      if (brands[i] === brand) {
        return true;
      }
      i = i + 1;
    }
    return false;
  }

  matchesPriceRange(lowestPrice: number): boolean {
    let label: string = this.selectedPriceLabel;
    if (label.length === 0) {
      return true;
    }
    let belowIndex: number = label.indexOf('以下');
    if (belowIndex >= 0) {
      let maxStr: string = label.substring(0, belowIndex);
      let maxVal: number = Number(maxStr);
      return lowestPrice <= maxVal;
    }
    let aboveIndex: number = label.indexOf('以上');
    if (aboveIndex >= 0) {
      let minStr: string = label.substring(0, aboveIndex);
      let minVal: number = Number(minStr);
      return lowestPrice >= minVal;
    }
    let dashIndex: number = label.indexOf('-');
    if (dashIndex >= 0) {
      let minStr: string = label.substring(0, dashIndex);
      let maxStr: string = label.substring(dashIndex + 1);
      let minVal: number = Number(minStr);
      let maxVal: number = Number(maxStr);
      return lowestPrice >= minVal && lowestPrice <= maxVal;
    }
    return false;
  }

  parseCommaList(str: string): string[] {
    if (str.length === 0) {
      return [];
    }
    let result: string[] = [];
    let current: string = '';
    let i: number = 0;
    while (i < str.length) {
      if (str.charAt(i) === ',') {
        if (current.length > 0) {
          result.push(current);
        }
        current = '';
      } else {
        current = current + str.charAt(i);
      }
      i = i + 1;
    }
    if (current.length > 0) {
      result.push(current);
    }
    return result;
  }

  applySort(): void {
    let sorted: Product[] = [];
    let i: number = 0;
    while (i < this.allFilteredProducts.length) {
      sorted.push(this.allFilteredProducts[i]);
      i = i + 1;
    }
    if (this.sortType === 'recommend') {
      sorted.sort((a: Product, b: Product): number => {
        return b.aggregateScore - a.aggregateScore;
      });
    } else if (this.sortType === 'priceLow') {
      sorted.sort((a: Product, b: Product): number => {
        return a.lowestPrice - b.lowestPrice;
      });
    } else if (this.sortType === 'rating') {
      sorted.sort((a: Product, b: Product): number => {
        return b.aggregateRating - a.aggregateRating;
      });
    }
    this.products = sorted;
  }

  changeSort(type: string): void {
    if (this.sortType === type) {
      return;
    }
    this.sortType = type;
    this.applySort();
  }

  getPlatformCount(): number {
    let platformNames: string[] = [];
    let i: number = 0;
    while (i < this.products.length) {
      let j: number = 0;
      while (j < this.products[i].platformListings.length) {
        let name: string = this.products[i].platformListings[j].platform;
        if (platformNames.indexOf(name) < 0) {
          platformNames.push(name);
        }
        j = j + 1;
      }
      i = i + 1;
    }
    return platformNames.length;
  }

  getFilterSummary(): string {
    let parts: string = this.categoryName;
    if (this.selectedBrands.length > 0) {
      parts = parts + ' > ' + this.selectedBrands;
    }
    if (this.selectedPriceLabel.length > 0) {
      parts = parts + ' > ' + this.selectedPriceLabel;
    }
    return parts;
  }

  navigateToDetail(product: Product): void {
    NavParams.productId = product.id;
    router.pushUrl({
      url: 'pages/ProductDetailPage'
    });
  }

  @Builder
  buildProductCardItem(product: Product): void {
    Column() {
      Column() {
        Row() {
          Column() {
            Text(product.name)
              .fontSize(16)
              .fontWeight(600)
              .fontColor('#1C1C1E')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(product.brand)
              .fontSize(12)
              .fontColor('#8E8E93')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column() {
            Text(formatPrice(product.lowestPrice))
              .fontSize(18)
              .fontWeight(700)
              .fontColor('#FF3B30')
            Text('起')
              .fontSize(11)
              .fontColor('#8E8E93')
          }
          .alignItems(HorizontalAlign.End)
          .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })

        Row() {
          Row() {
            Text('\u2605 ' + product.aggregateRating.toFixed(1))
              .fontSize(12)
              .fontColor('#FF9500')
            Text(' ' + product.totalReviewCount.toString() + '评')
              .fontSize(11)
              .fontColor('#8E8E93')
          }
          .margin({ right: 12 })

          Text('价差 ' + formatPrice(product.priceSpread))
            .fontSize(11)
            .fontColor('#34C759')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#E8F8ED')
            .borderRadius(10)

          Blank()

          Text(product.platformListings.length.toString() + '平台在售')
            .fontSize(11)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 12 })
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .margin({ left: 16, right: 16, top: 6, bottom: 0 })
      .onClick(() => {
        this.navigateToDetail(product);
      })
    }
  }

  @Builder
  buildSortTabs(): void {
    Row() {
      this.buildSortTabItem('recommend', '综合推荐')
      this.buildSortTabItem('priceLow', '价格最低')
      this.buildSortTabItem('rating', '评分最高')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 0, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildSortTabItem(type: string, label: string): void {
    Column() {
      Text(label)
        .fontSize(15)
        .fontWeight(this.sortType === type ? 600 : 400)
        .fontColor(this.sortType === type ? '#007AFF' : '#8E8E93')
        .padding({ top: 10, bottom: 8 })

      if (this.sortType === type) {
        Divider()
          .width(24)
          .height(3)
          .color('#007AFF')
          .borderRadius(1.5)
      } else {
        Divider()
          .width(24)
          .height(3)
          .color(Color.Transparent)
          .borderRadius(1.5)
      }
    }
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 28 })
    .onClick(() => {
      this.changeSort(type);
    })
  }

  @Builder
  buildEmptyState(): void {
    Column() {
      Text('🔍')
        .fontSize(64)
        .margin({ bottom: 16 })
      Text('没有找到匹配的商品')
        .fontSize(16)
        .fontColor('#3C3C3C')
        .fontWeight(500)
        .margin({ bottom: 8 })
      Text('调整筛选条件')
        .fontSize(14)
        .fontColor('#007AFF')
        .padding({ left: 24, right: 24, top: 10, bottom: 10 })
        .borderRadius(20)
        .borderWidth(1)
        .borderColor('#007AFF')
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .padding({ top: 80 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildSkeletonList(): void {
    Column() {
      ForEach([0, 1, 2, 3, 4, 5], (item: number) => {
        Row() {
          Column() {
            Row()
              .width('60%')
              .height(16)
              .backgroundColor('#E5E5EA')
              .borderRadius(4)
              .margin({ bottom: 8 })
            Row()
              .width('40%')
              .height(12)
              .backgroundColor('#E5E5EA')
              .borderRadius(4)
              .margin({ bottom: 12 })
            Row()
              .width('80%')
              .height(12)
              .backgroundColor('#E5E5EA')
              .borderRadius(4)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column()
            .width(60)
            .height(20)
            .backgroundColor('#E5E5EA')
            .borderRadius(4)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .margin({ left: 16, right: 16, top: 6, bottom: 0 })
      })
    }
    .width('100%')
    .padding({ top: 12 })
  }

  @Builder
  buildSummaryBar(): void {
    Row() {
      Text('共找到 ' + this.products.length.toString() + ' 款商品，来自 ' + this.getPlatformCount().toString() + ' 个平台')
        .fontSize(13)
        .fontColor('#8E8E93')
    }
    .width('100%')
    .padding(16)
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
        Text(this.getFilterSummary())
          .fontSize(14)
          .fontColor('#3C3C3C')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      this.buildSortTabs()

      if (this.isLoading) {
        this.buildSkeletonList()
      } else if (this.products.length === 0) {
        this.buildEmptyState()
      } else {
        Column() {
          this.buildSummaryBar()

          List() {
            ForEach(this.products, (product: Product, index: number) => {
              ListItem() {
                this.buildProductCardItem(product)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .backgroundColor('#F2F2F7')
        }
        .width('100%')
        .layoutWeight(1)
      }

      if (!this.isLoading && this.products.length > 0) {
        Row() {
          Button('详细对比表')
            .fontSize(15)
            .fontColor('#007AFF')
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .borderWidth(1)
            .borderColor('#007AFF')
            .layoutWeight(1)
            .height(44)
            .onClick(() => {
              NavParams.categoryId = NavParams.categoryId
              NavParams.categoryName = this.categoryName
              NavParams.selectedBrands = this.selectedBrands
              NavParams.selectedPriceLabel = this.selectedPriceLabel
              router.pushUrl({ url: 'pages/CompareTablePage' })
            })

          Blank().width(12)

          Button('只看最低价')
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(24)
            .layoutWeight(1)
            .height(44)
            .onClick(() => {
              if (this.allFilteredProducts.length === 0) {
                return;
              }
              let cheapest: Product = this.allFilteredProducts[0];
              let j: number = 1;
              while (j < this.allFilteredProducts.length) {
                if (this.allFilteredProducts[j].lowestPrice < cheapest.lowestPrice) {
                  cheapest = this.allFilteredProducts[j];
                }
                j = j + 1;
              }
              this.navigateToDetail(cheapest);
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor('#FFFFFF')
        .height(56)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}
