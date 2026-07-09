import { router } from '@kit.ArkUI'
import { Product } from '../models/DataModels'
import { DataProvider } from '../data/DataProvider'
import { NavParams } from '../utils/PreferenceManager'
import { ProductCompareTable } from '../components/ProductCompareTable'

@Entry
@Component
struct CompareTablePage {
  @State products: Product[] = []

  aboutToAppear(): void {
    let categoryId: string = NavParams.categoryId
    let selectedBrands: string = NavParams.selectedBrands
    let selectedPriceLabel: string = NavParams.selectedPriceLabel
    this.loadData(categoryId, selectedBrands, selectedPriceLabel)
  }

  loadData(categoryId: string, selectedBrands: string, selectedPriceLabel: string): void {
    let allProducts: Product[] = DataProvider.getProductRepository().getProducts()
    let categoryField: string = ''
    if (categoryId.length > 4) {
      categoryField = categoryId.substring(4)
    }
    let filtered: Product[] = []
    let i: number = 0
    while (i < allProducts.length) {
      let product: Product = allProducts[i]
      let matches: boolean = true
      if (categoryField.length > 0) {
        if (product.category !== categoryField) {
          matches = false
        }
      }
      if (matches && selectedBrands.length > 0) {
        let brands: string[] = this.parseCommaList(selectedBrands)
        let brandMatch: boolean = false
        let b: number = 0
        while (b < brands.length) {
          if (brands[b] === product.brand) {
            brandMatch = true
            break
          }
          b = b + 1
        }
        if (!brandMatch) {
          matches = false
        }
      }
      if (matches) {
        filtered.push(product)
      }
      i = i + 1
    }
    this.products = filtered
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

  build() {
    Column() {
      Row() {
        Text('\u2190')
          .fontSize(24)
          .fontColor('#1C1C1E')
          .padding({ right: 12 })
          .onClick(() => {
            router.back()
          })
        Text('商品详细对比')
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#1C1C1E')
          .layoutWeight(1)

        if (this.products.length > 0) {
          Text(this.products.length.toString() + '款商品')
            .fontSize(13)
            .fontColor('#8E8E93')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (this.products.length === 0) {
        Column({ space: 16 }) {
          Text('\uD83D\uDCCA')
            .fontSize(64)
          Text('暂无可对比的商品')
            .fontSize(16)
            .fontColor('#8E8E93')
          Button('返回')
            .fontSize(15)
            .fontColor('#007AFF')
            .backgroundColor('#FFFFFF')
            .borderRadius(22)
            .borderWidth(1)
            .borderColor('#007AFF')
            .padding({ left: 32, right: 32 })
            .onClick(() => {
              router.back()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#F2F2F7')
      }

      if (this.products.length > 0) {
        Scroll() {
          Column() {
            Text('横向滑动查看更多')
              .fontSize(12)
              .fontColor('#8E8E93')
              .width('100%')
              .padding({ left: 16, top: 12, bottom: 8 })

            ProductCompareTable({ products: this.products })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F2F2F7')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}
