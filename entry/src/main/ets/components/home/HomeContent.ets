import { router } from '@kit.ArkUI'
import { Category } from '../../models/DataModels'
import { MockData } from '../../data/MockData'
import { NavParams } from '../../utils/PreferenceManager'
import { RecommendationItem } from '../../models/RecommendationModels'
import { SearchBar } from '../SearchBar'
import { CategoryIconGrid } from '../CategoryIconGrid'
import { RecommendationSection } from '../RecommendationSection'
import { HomeGreeting } from './HomeGreeting'

@Component
export struct HomeContent {
  onSwitchTab: (index: number) => void =
    (index: number): void => {}

  @Prop recommendations: RecommendationItem[] = []

  build() {
    Scroll() {
      Column() {
        HomeGreeting()

        SearchBar({
          onSearchClick: (): void => {
            router.pushUrl({ url: 'pages/SearchPage' })
          }
        })
          .margin({ bottom: 22 })

        Column({ space: 12 }) {
          Text('商品分类')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .width('100%')

          CategoryIconGrid({
            categories: MockData.getCategories(),
            columns: 3,
            onCategoryClick: (category: Category): void => {
              NavParams.categoryId = category.id
              NavParams.categoryName = category.name

              router.pushUrl({
                url: 'pages/CategoryFilterPage'
              })
            }
          })
        }
        .width('100%')
        .margin({ bottom: 24 })

        RecommendationSection({
          title: '为你推荐',
          items: this.recommendations,
          onSeeMore: (): void => {
            this.onSwitchTab(1)
          }
        })
          .margin({ bottom: 24 })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        bottom: 24
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
    .scrollBar(BarState.Off)
  }
}
