import { RecommendationItem } from '../models/RecommendationModels'
import { RecommendationEngine } from '../utils/RecommendationEngine'
import { HomeContent } from '../components/home/HomeContent'
import { DiscoverContent } from '../components/home/DiscoverContent'
import { FavoritesContent } from '../components/home/FavoritesContent'
import { ProfileContent } from '../components/home/ProfileContent'
import { BottomTabItem } from '../components/home/BottomTabItem'

@Entry
@Component
export struct HomePage {
  @State currentTabIndex: number = 0
  @State homeRecommendations: RecommendationItem[] = []
  @State favoritesVersion: number = 0

  aboutToAppear(): void {
    this.refreshRecommendations()
  }

  onPageShow(): void {
    this.refreshRecommendations()
    this.favoritesVersion = this.favoritesVersion + 1
  }

  private refreshRecommendations(): void {
    let engine = RecommendationEngine.getInstance()
    engine.refresh()
    this.homeRecommendations = engine.recommend(10)
  }

  @Builder TabBarBuilder(index: number) {
    BottomTabItem({
      index: index,
      isSelected: this.currentTabIndex === index,
      onTabClick: (): void => {
        this.currentTabIndex = index
      }
    })
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      index: this.currentTabIndex
    }) {
      TabContent() {
        HomeContent({
          recommendations: this.homeRecommendations,
          onSwitchTab: (index: number): void => {
            this.currentTabIndex = index
          }
        })
      }
      .tabBar(this.TabBarBuilder(0))

      TabContent() {
        DiscoverContent()
      }
      .tabBar(this.TabBarBuilder(1))

      TabContent() {
        FavoritesContent({
          favoritesVersion: this.favoritesVersion
        })
      }
      .tabBar(this.TabBarBuilder(2))

      TabContent() {
        ProfileContent({
          onSwitchTab: (index: number): void => {
            this.currentTabIndex = index
          }
        })
      }
      .tabBar(this.TabBarBuilder(3))
    }
    .barWidth('100%')
    .onChange((index: number) => {
      this.currentTabIndex = index
    })
    .width('100%')
    .height('100%')
  }
}
