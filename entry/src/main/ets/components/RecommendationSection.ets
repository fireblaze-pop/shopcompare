import { router } from '@kit.ArkUI'
import { RecommendationItem } from '../models/RecommendationModels'
import { RecommendationCard } from './RecommendationCard'
import { NavParams } from '../utils/PreferenceManager'

@Component
export struct RecommendationSection {
  @Prop title: string = '为你推荐'
  @Prop items: RecommendationItem[] = []
  onSeeMore: () => void = (): void => {}

  private onItemClick(productId: string): void {
    NavParams.productId = productId
    router.pushUrl({
      url: 'pages/ProductDetailPage',
      params: { productId: productId }
    })
  }

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Blank()

        if (this.items.length > 0) {
          Text('查看更多')
            .fontSize(14)
            .fontColor('#007AFF')
            .onClick(() => {
              this.onSeeMore()
            })
        }
      }
      .width('100%')
      .padding({ left: 4, right: 4 })

      if (this.items.length === 0) {
        Column({ space: 8 }) {
          Text('📭')
            .fontSize(40)
          Text('暂无推荐，去发现更多')
            .fontSize(14)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .height(160)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .margin({ top: 12 })
      }

      if (this.items.length > 0) {
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.items, (item: RecommendationItem) => {
              RecommendationCard({
                item: item,
                cardWidth: 280,
                onCardClick: (productId: string): void => {
                  this.onItemClick(productId)
                }
              })
            }, (item: RecommendationItem) => item.product.id)
          }
          .padding({ left: 4, right: 4 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
  }
}
