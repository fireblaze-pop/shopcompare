import { Product } from '../models/DataModels'
import { RecommendationItem, SOURCE_USER_CF, SOURCE_ITEM_CF, SOURCE_COLD_START, SOURCE_POPULAR } from '../models/RecommendationModels'
import { ProductCard } from './ProductCard'

function emptyProduct(): Product {
  let product: Product = {
    id: '', name: '', modelCode: '', brand: '', category: '', imageUrl: '',
    specs: [], aggregateScore: 0, aggregateRating: 0, totalReviewCount: 0,
    platformListings: [], lowestPrice: 0, priceSpread: 0, historicalLow: 0,
    priceHistory: [], reviewTags: [], publishDate: '', description: ''
  }
  return product
}

function emptyItem(): RecommendationItem {
  let item: RecommendationItem = {
    product: emptyProduct(), score: 0, reason: '', source: SOURCE_POPULAR
  }
  return item
}

@Component
export struct RecommendationCard {
  @Prop item: RecommendationItem = emptyItem()
  @Prop cardWidth: number = 280
  onCardClick: (productId: string) => void = (id: string): void => {}

  private reasonColor(): string {
    if (this.item.source === SOURCE_USER_CF) {
      return '#AF52DE'
    }
    if (this.item.source === SOURCE_ITEM_CF) {
      return '#007AFF'
    }
    if (this.item.source === SOURCE_COLD_START) {
      return '#34C759'
    }
    return '#FF9500'
  }

  private reasonBg(): string {
    if (this.item.source === SOURCE_USER_CF) {
      return '#F2EBFE'
    }
    if (this.item.source === SOURCE_ITEM_CF) {
      return '#EBF5FF'
    }
    if (this.item.source === SOURCE_COLD_START) {
      return '#E8F8ED'
    }
    return '#FFF4E6'
  }

  private reasonIcon(): string {
    if (this.item.source === SOURCE_USER_CF) {
      return '🧑‍🤝‍🧑'
    }
    if (this.item.source === SOURCE_ITEM_CF) {
      return '🔗'
    }
    if (this.item.source === SOURCE_COLD_START) {
      return '🎯'
    }
    return '🔥'
  }

  build() {
    Column() {
      Row() {
        Text(this.reasonIcon())
          .fontSize(11)
        Text(this.item.reason)
          .fontSize(11)
          .fontColor(this.reasonColor())
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 4 })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.reasonBg())
      .borderRadius({ topLeft: 16, topRight: 16 })
      .alignItems(VerticalAlign.Center)

      ProductCard({
        product: this.item.product,
        cardWidth: this.cardWidth,
        showPlatforms: false,
        onCardClick: (): void => {
          this.onCardClick(this.item.product.id)
        }
      })
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16 })
    }
    .width(this.cardWidth)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, offsetY: 2, color: '#1A000000' })
    .onClick(() => {
      this.onCardClick(this.item.product.id)
    })
  }
}
