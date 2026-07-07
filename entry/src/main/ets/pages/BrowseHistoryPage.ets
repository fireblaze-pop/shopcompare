import { router } from '@kit.ArkUI'
import { Product } from '../models/DataModels'
import { UserAction, ACTION_VIEW, ACTION_CLICK, ACTION_FAVORITE, ACTION_RATE, ACTION_SEARCH } from '../models/RecommendationModels'
import { DataProvider } from '../data/DataProvider'
import { BehaviorManager } from '../utils/BehaviorManager'
import { ProductRepository } from '../data/repository/ProductRepository'
import { NavParams } from '../utils/PreferenceManager'

interface HistoryEntry {
  product: Product
  timestamp: number
  actionLabel: string
}

@Entry
@Component
struct BrowseHistoryPage {
  @State historyEntries: HistoryEntry[] = []

  aboutToAppear(): void {
    this.loadHistory()
  }

  private loadHistory(): void {
    let behavior = BehaviorManager.getInstance()
    let actions: UserAction[] = behavior.getActions()
    let repo: ProductRepository = DataProvider.getProductRepository()
    let entries: HistoryEntry[] = []
    let i: number = 0
    while (i < actions.length) {
      let action: UserAction = actions[i]
      if (action.actionType === ACTION_SEARCH) {
        i = i + 1
        continue
      }
      let product: Product | undefined = repo.getProductById(action.productId)
      if (product === undefined) {
        i = i + 1
        continue
      }
      let found: boolean = false
      let j: number = 0
      while (j < entries.length) {
        if (entries[j].product.id === action.productId) {
          if (action.timestamp > entries[j].timestamp) {
            entries[j].timestamp = action.timestamp
            entries[j].actionLabel = this.actionLabel(action.actionType)
          }
          found = true
          break
        }
        j = j + 1
      }
      if (!found) {
        let entry: HistoryEntry = {
          product: product,
          timestamp: action.timestamp,
          actionLabel: this.actionLabel(action.actionType)
        }
        entries.push(entry)
      }
      i = i + 1
    }
    entries.sort((a: HistoryEntry, b: HistoryEntry): number => {
      return b.timestamp - a.timestamp
    })
    this.historyEntries = entries
  }

  private actionLabel(actionType: number): string {
    if (actionType === ACTION_VIEW) {
      return '浏览过'
    }
    if (actionType === ACTION_CLICK) {
      return '点击过'
    }
    if (actionType === ACTION_FAVORITE) {
      return '收藏过'
    }
    if (actionType === ACTION_RATE) {
      return '评过分的'
    }
    return '浏览过'
  }

  private formatTime(ts: number): string {
    let date = new Date(ts * 1000)
    let month: number = date.getMonth() + 1
    let day: number = date.getDate()
    let hour: number = date.getHours()
    let minute: number = date.getMinutes()
    let mStr: string = month < 10 ? '0' + month.toString() : month.toString()
    let dStr: string = day < 10 ? '0' + day.toString() : day.toString()
    let hStr: string = hour < 10 ? '0' + hour.toString() : hour.toString()
    let minStr: string = minute < 10 ? '0' + minute.toString() : minute.toString()
    return mStr + '-' + dStr + ' ' + hStr + ':' + minStr
  }

  private navigateToDetail(product: Product): void {
    NavParams.productId = product.id
    router.pushUrl({
      url: 'pages/ProductDetailPage',
      params: { productId: product.id }
    })
  }

  @Builder
  buildHistoryItem(entry: HistoryEntry): void {
    Row() {
      Column() {
        if (entry.product.imageUrl.length > 0) {
          Image(entry.product.imageUrl)
            .width(64)
            .height(64)
            .objectFit(ImageFit.Cover)
        }
        if (entry.product.imageUrl.length === 0) {
          Text('\uD83D\uDCE6')
            .fontSize(32)
        }
      }
      .width(64)
      .height(64)
      .borderRadius(8)
      .backgroundColor('#F2F2F7')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text(entry.product.name)
          .fontSize(15)
          .fontWeight(500)
          .fontColor('#1C1C1E')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(entry.actionLabel)
            .fontSize(11)
            .fontColor('#007AFF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#EBF5FF')
            .borderRadius(4)
          Text(' ' + this.formatTime(entry.timestamp))
            .fontSize(11)
            .fontColor('#8E8E93')
        }
        .margin({ top: 6 })

        Row() {
          Text('\u00A5' + entry.product.lowestPrice.toFixed(0))
            .fontSize(16)
            .fontWeight(700)
            .fontColor('#FF3B30')
          Text('起')
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ left: 4 })
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 6, bottom: 0 })
    .onClick(() => {
      this.navigateToDetail(entry.product)
    })
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
        Text('浏览历史')
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#1C1C1E')
          .layoutWeight(1)
        if (this.historyEntries.length > 0) {
          Text('共' + this.historyEntries.length.toString() + '条')
            .fontSize(13)
            .fontColor('#8E8E93')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (this.historyEntries.length === 0) {
        Column({ space: 16 }) {
          Text('\uD83D\uDD52')
            .fontSize(64)
          Text('暂无浏览记录')
            .fontSize(16)
            .fontColor('#8E8E93')
          Text('去看看有什么好物吧')
            .fontSize(14)
            .fontColor('#8E8E93')
          Button('去逛逛')
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor('#007AFF')
            .borderRadius(22)
            .padding({ left: 32, right: 32 })
            .margin({ top: 12 })
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

      if (this.historyEntries.length > 0) {
        Scroll() {
          Column() {
            ForEach(this.historyEntries, (entry: HistoryEntry) => {
              this.buildHistoryItem(entry)
            }, (entry: HistoryEntry) => entry.product.id + entry.timestamp.toString())
          }
          .width('100%')
          .padding({ top: 8, bottom: 20 })
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
