import { router } from '@kit.ArkUI'
import { Product } from '../models/DataModels'
import { DataProvider } from '../data/DataProvider'
import { ProductRepository } from '../data/repository/ProductRepository'
import { NavParams } from '../utils/PreferenceManager'
import { ProductCompareTable } from '../components/ProductCompareTable'

@Entry
@Component
struct CompareTablePage {
  @State products: Product[] = []
  @State isLoading: boolean = true

  aboutToAppear(): void {
    this.loadData(NavParams.compareProductIds)
  }

  async loadData(productIds: string): Promise<void> {
    this.isLoading = true

    let ids: string[] = this.parseCommaList(productIds)
    let loaded: Product[] = []
    let repo: ProductRepository = DataProvider.getProductRepository()
    let i: number = 0

    while (i < ids.length) {
      let product: Product | undefined =
        await repo.loadProductDetail(ids[i])

      if (product === undefined) {
        product = repo.getProductById(ids[i])
      }

      if (product !== undefined) {
        loaded.push(product)
      }

      i = i + 1
    }

    this.products = loaded
    this.isLoading = false
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
        Text('商品对比')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Text('把关键差异放在同一张表里')
          .fontSize(11)
          .fontColor('#8E8E93')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.products.length > 0) {
        Text(this.products.length.toString() + ' 款')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5267E8')
          .padding({
            left: 10,
            right: 10,
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
      right: 14
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  @Builder
  buildIntroCard(): void {
    Column() {
      Text('重点差异，一眼看懂')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .width('100%')

      Text(
        '已选择 ' +
        this.products.length.toString() +
        ' 款商品。横向滑动查看价格、平台覆盖与规格差异。'
      )
        .fontSize(13)
        .fontColor('#6E7178')
        .lineHeight(20)
        .width('100%')
        .margin({ top: 6 })

      Row({ space: 8 }) {
        Text('价格')
          .fontSize(11)
          .fontColor('#FF3B30')
          .padding({
            left: 9,
            right: 9,
            top: 5,
            bottom: 5
          })
          .backgroundColor('#FFF1F0')
          .borderRadius(8)

        Text('平台')
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

        Text('规格')
          .fontSize(11)
          .fontColor('#2D8A4E')
          .padding({
            left: 9,
            right: 9,
            top: 5,
            bottom: 5
          })
          .backgroundColor('#EEF9F1')
          .borderRadius(8)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
  }

  @Builder
  buildLoadingState(): void {
    Column({ space: 12 }) {
      Text('正在加载商品详情')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1C1E')

      Text('正在读取规格和平台信息…')
        .fontSize(13)
        .fontColor('#8E8E93')
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F5F6F8')
  }

  @Builder
  buildEmptyState(): void {
    Column({ space: 14 }) {
      Text('暂无可对比商品')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1C1E')

      Text('请返回筛选结果，选择 2–4 款商品进行对比')
        .fontSize(13)
        .fontColor('#8E8E93')
        .textAlign(TextAlign.Center)

      Button('返回选择')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#5267E8')
        .backgroundColor(Color.White)
        .borderRadius(13)
        .border({
          width: 1,
          color: '#5267E8'
        })
        .height(42)
        .padding({ left: 26, right: 26 })
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
  buildDataNote(): void {
    Column() {
      Text('数据说明')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1C1E')
        .width('100%')

      Text('规格数据来自商品详情；缺失项以“—”显示。当前价格数据仍以服务器返回结果为准。')
        .fontSize(12)
        .fontColor('#8E8E93')
        .lineHeight(19)
        .width('100%')
        .margin({ top: 5 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
  }

  build() {
    Column() {
      this.buildTopBar()

      if (this.isLoading) {
        this.buildLoadingState()
      } else if (this.products.length < 2) {
        this.buildEmptyState()
      } else {
        Scroll() {
          Column({ space: 12 }) {
            this.buildIntroCard()

            Column() {
              ProductCompareTable({
                products: this.products
              })
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(16)
            .clip(true)
            .border({
              width: 1,
              color: '#ECEEF2'
            })

            this.buildDataNote()
          }
          .width('100%')
          .padding({
            left: 12,
            right: 12,
            top: 12,
            bottom: 20
          })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F6F8')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
