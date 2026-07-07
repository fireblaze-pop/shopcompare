import { router } from '@kit.ArkUI'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { Category, Product } from '../models/DataModels'
import { MockData } from '../data/MockData'
import { PreferenceManager } from '../utils/PreferenceManager'
import { NavParams } from '../utils/PreferenceManager'
import { SearchBar } from '../components/SearchBar'
import { ProductCard } from '../components/ProductCard'
import { RecommendationItem } from '../models/RecommendationModels'
import { RecommendationEngine } from '../utils/RecommendationEngine'
import { RecommendationSection } from '../components/RecommendationSection'
import { BehaviorManager } from '../utils/BehaviorManager'

let TAB_LABELS: string[] = ['首页', '发现', '收藏', '我的']

@Component
struct HomeContent {
  onSwitchTab: (index: number) => void = (index: number): void => {}
  @Prop recommendations: RecommendationItem[] = []

  @State greetingHeight: number = 64
  @State greetingOpacity: number = 1
  @State greetingBottomMargin: number = 16

  private greetingTimer: number = -1

  aboutToAppear(): void {
    this.greetingHeight = 64
    this.greetingOpacity = 1
    this.greetingBottomMargin = 16

    this.greetingTimer = setTimeout(() => {
      animateTo({
        duration: 450,
        curve: Curve.EaseInOut
      }, () => {
        this.greetingHeight = 0
        this.greetingOpacity = 0
        this.greetingBottomMargin = 0
      })
    }, 1800)
  }

  aboutToDisappear(): void {
    if (this.greetingTimer !== -1) {
      clearTimeout(this.greetingTimer)
      this.greetingTimer = -1
    }
  }

  @Builder CategoryIconBuilder(index: number) {
    if (index === 0) {
      Image($r('app.media.category_phone'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 1) {
      Image($r('app.media.category_laptop'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 2) {
      Image($r('app.media.category_appliance'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 3) {
      Image($r('app.media.category_beauty'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else if (index === 4) {
      Image($r('app.media.category_clothing'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    } else {
      Image($r('app.media.category_food'))
        .width(27)
        .height(27)
        .objectFit(ImageFit.Contain)
    }
  }

  @Builder CategoryGridBuilder() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(MockData.getCategories(), (category: Category, index: number) => {
        Column({ space: 8 }) {
          Column() {
            this.CategoryIconBuilder(index)
          }
          .width(54)
          .height(54)
          .borderRadius(16)
          .backgroundColor('#EEF1FF')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Text(category.name)
            .fontSize(13)
            .fontColor('#3C3C43')
            .maxLines(1)
        }
        .width('33.33%')
        .margin({ bottom: 16 })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          NavParams.categoryId = category.id
          NavParams.categoryName = category.name
          router.pushUrl({
            url: 'pages/CategoryFilterPage'
          })
        })
      }, (category: Category) => category.id)
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column() {
        // 欢迎区域
        Column({ space: 6 }) {
          Text('你好，购物达人 👋')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text('今天想比什么？')
            .fontSize(14)
            .fontColor('#8E8E93')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .height(this.greetingHeight)
        .opacity(this.greetingOpacity)
        .margin({
          top: 20,
          bottom: this.greetingBottomMargin
        })
        .clip(true)

        // 搜索入口
        SearchBar({
          onSearchClick: (): void => {
            router.pushUrl({ url: 'pages/SearchPage' })
          }
        })
          .margin({ bottom: 22 })

        // 商品分类
        Column({ space: 12 }) {
          Text('商品分类')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .width('100%')

          this.CategoryGridBuilder()
        }
        .width('100%')
        .margin({ bottom: 24 })

        // 个性化推荐
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

@Component
struct DiscoverContent {
  build() {
    Column() {
      Text('发现好物')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .width('100%')
        .padding({ left: 16, top: 16, bottom: 12 })

      List() {
        ForEach(MockData.getProducts(), (product: Product) => {
          ListItem() {
            Column() {
              ProductCard({ product: product })
            }
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
            .onClick(() => {
              NavParams.productId = product.id
              router.pushUrl({
                url: 'pages/ProductDetailPage',
                params: { productId: product.id }
              })
            })
          }
        }, (product: Product) => product.id)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.5,
        color: '#E5E5EA',
        startMargin: 16,
        endMargin: 16
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}

@Component
struct FavoritesContent {
  @Prop @Watch('onVersionChange') favoritesVersion: number = 0
  @State favoriteProducts: Product[] = []

  aboutToAppear(): void {
    this.loadFavorites()
  }

  onVersionChange(): void {
    this.loadFavorites()
  }

  private loadFavorites(): void {
    let ids: string[] = PreferenceManager.getFavoriteIds()
    let allProducts: Product[] = MockData.getProducts()
    let filtered: Product[] = []
    let i: number = 0
    while (i < allProducts.length) {
      let product: Product = allProducts[i]
      let found: boolean = false
      let j: number = 0
      while (j < ids.length) {
        if (ids[j] === product.id) {
          found = true
          break
        }
        j = j + 1
      }
      if (found) {
        filtered.push(product)
      }
      i = i + 1
    }
    this.favoriteProducts = filtered
  }

  @Builder DeleteSwipeBuilder() {
    Text('取消收藏')
      .fontSize(14)
      .fontColor(Color.White)
      .width(80)
      .height('100%')
      .textAlign(TextAlign.Center)
      .backgroundColor('#FF3B30')
  }

  build() {
    Column() {
      Text('我的收藏')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .width('100%')
        .padding({ left: 16, top: 16, bottom: 12 })

      if (this.favoriteProducts.length === 0) {
        Column({ space: 16 }) {
          Text('💝')
            .fontSize(64)

          Text('还没有收藏商品')
            .fontSize(16)
            .fontColor('#8E8E93')

          Button('去逛逛')
            .fontSize(15)
            .fontColor(Color.White)
            .backgroundColor('#007AFF')
            .borderRadius(22)
            .padding({ left: 32, right: 32 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/SearchPage'
              })
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      if (this.favoriteProducts.length > 0) {
        List() {
          ForEach(this.favoriteProducts, (product: Product, index: number) => {
            ListItem() {
              Column() {
                ProductCard({ product: product })
              }
              .padding({ left: 16, right: 16, top: 4, bottom: 4 })
              .onClick(() => {
                NavParams.productId = product.id
                router.pushUrl({
                  url: 'pages/ProductDetailPage',
                  params: { productId: product.id }
                })
              })
            }
            .swipeAction({
              end: {
                builder: () => {
                  this.DeleteSwipeBuilder()
                },
                onAction: () => {
                  PreferenceManager.removeFavorite(product.id)
                  let newArr: Product[] = []
                  let k: number = 0
                  while (k < this.favoriteProducts.length) {
                    if (k !== index) {
                      newArr.push(this.favoriteProducts[k])
                    }
                    k = k + 1
                  }
                  this.favoriteProducts = newArr
                }
              }
            })
          }, (product: Product) => product.id)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({
          strokeWidth: 0.5,
          color: '#E5E5EA',
          startMargin: 16,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}

@Component
struct ProfileContent {
  onSwitchTab: (index: number) => void = (index: number): void => {}
  @State darkModeEnabled: boolean = false
  @State notificationEnabled: boolean = true

  aboutToAppear(): void {
    this.darkModeEnabled = PreferenceManager.getDarkMode()
    this.notificationEnabled = PreferenceManager.getNotificationEnabled()
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 0 }) {
          Column({ space: 8 }) {
            Column() {
              Text('👤')
                .fontSize(32)
            }
            .width(72)
            .height(72)
            .borderRadius(36)
            .backgroundColor('#E5E5EA')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text('购物达人')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')

            Text('已为你对比' + MockData.getProductCount().toString() + '款商品')
              .fontSize(14)
              .fontColor('#8E8E93')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 32, bottom: 24 })

          Column() {
            Text('')
              .height(0)
          }
          .width('100%')
          .height(8)
          .backgroundColor('#F2F2F7')

          this.MenuItemBuilder('📋', '偏好管理', false, false, false, (): void => {
            router.pushUrl({ url: 'pages/QuestionnairePage' })
          })

          this.MenuItemBuilder('❤️', '我的收藏', false, false, false, (): void => {
            this.onSwitchTab(2)
          })

          this.MenuItemBuilder('🕐', '浏览历史', false, false, false, (): void => {
            router.pushUrl({ url: 'pages/BrowseHistoryPage' })
          })

          Column() {
            Text('')
              .height(0)
          }
          .width('100%')
          .height(8)
          .backgroundColor('#F2F2F7')

          Column() {
            Text('⚙ 设置')
              .fontSize(13)
              .fontColor('#8E8E93')
              .padding({ left: 16, top: 14, bottom: 6 })
              .width('100%')
          }
          .width('100%')
          .backgroundColor(Color.White)

          this.MenuItemBuilder('🌙', '深色模式', true, this.darkModeEnabled, false, (): void => {})

          this.MenuItemBuilder('🔔', '通知设置', true, this.notificationEnabled, false, (): void => {})

          this.MenuItemBuilder('ℹ️', '关于我们', false, false, true, (): void => {
            router.pushUrl({ url: 'pages/AboutPage' })
          })

          Column() {
            Text('')
              .height(0)
          }
          .width('100%')
          .height(24)
          .backgroundColor('#F2F2F7')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Button('退出登录')
        .fontSize(16)
        .fontColor('#FF3B30')
        .backgroundColor(Color.Transparent)
        .width('100%')
        .height(52)
        .margin({ bottom: 8 })
        .onClick(() => {
          PreferenceManager.setDarkMode(false)
          PreferenceManager.setNotificationEnabled(true)
          PreferenceManager.saveUserProfile({
            preferences: [], dimensions: [], budget: '', platforms: [], isFirstLaunch: true
          })
          BehaviorManager.getInstance().clearActions()
          router.replaceUrl({ url: 'pages/LoginPage' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder MenuItemBuilder(
    icon: string,
    label: string,
    hasToggle: boolean,
    toggleValue: boolean,
    showVersion: boolean,
    onClick: () => void
  ) {
    Row() {
      Text(icon)
        .fontSize(20)
        .margin({ left: 16 })

      Text(label)
        .fontSize(16)
        .fontColor('#1C1C1E')
        .margin({ left: 12 })

      Blank()

      if (hasToggle) {
        Toggle({ type: ToggleType.Switch, isOn: toggleValue })
          .onChange((value: boolean) => {
            if (label === '深色模式') {
              this.darkModeEnabled = value
              PreferenceManager.setDarkMode(value)
              let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
              let appContext = context.getApplicationContext()
              if (value) {
                appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
              } else {
                appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
              }
            }
            if (label === '通知设置') {
              this.notificationEnabled = value
              PreferenceManager.setNotificationEnabled(value)
            }
          })
          .margin({ right: 16 })
      }

      if (showVersion) {
        Text('v1.0.0')
          .fontSize(14)
          .fontColor('#C7C7CC')
          .margin({ right: 12 })
      }

      if (!hasToggle && !showVersion) {
        Text('›')
          .fontSize(20)
          .fontColor('#C7C7CC')
          .margin({ right: 16 })
      }
    }
    .width('100%')
    .height(52)
    .backgroundColor(Color.White)
    .onClick(() => {
      if (!hasToggle) {
        onClick()
      }
    })

    if (!hasToggle && !showVersion) {
      Divider()
        .strokeWidth(0.5)
        .color('#E5E5EA')
        .margin({ left: 52 })
    }
  }
}

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

  @Builder TabIconBuilder(index: number) {
    if (index === 0) {
      Image($r('app.media.tab_home'))
        .width(23)
        .height(23)
        .objectFit(ImageFit.Contain)
        .opacity(this.currentTabIndex === index ? 1 : 0.42)
    } else if (index === 1) {
      Image($r('app.media.tab_discover'))
        .width(23)
        .height(23)
        .objectFit(ImageFit.Contain)
        .opacity(this.currentTabIndex === index ? 1 : 0.42)
    } else if (index === 2) {
      Image($r('app.media.tab_favorite'))
        .width(23)
        .height(23)
        .objectFit(ImageFit.Contain)
        .opacity(this.currentTabIndex === index ? 1 : 0.42)
    } else {
      Image($r('app.media.tab_profile'))
        .width(23)
        .height(23)
        .objectFit(ImageFit.Contain)
        .opacity(this.currentTabIndex === index ? 1 : 0.42)
    }
  }

  @Builder TabBarBuilder(index: number) {
    Column({ space: 4 }) {
      Column() {
        this.TabIconBuilder(index)
      }
      .width(36)
      .height(28)
      .borderRadius(10)
      .backgroundColor(this.currentTabIndex === index ? '#EEF1FF' : Color.Transparent)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(TAB_LABELS[index])
        .fontSize(11)
        .fontColor(this.currentTabIndex === index ? '#5267E8' : '#8E8E93')
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(Color.White)
    .onClick(() => {
      this.currentTabIndex = index
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
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
        FavoritesContent({ favoritesVersion: this.favoritesVersion })
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
