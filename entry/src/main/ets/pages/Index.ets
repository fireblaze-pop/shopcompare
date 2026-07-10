import { NavRouter } from '../utils/NavRouter'

@Entry
@Component
struct Index {
  @Provide('navPathStack') navPathStack: NavPathStack = NavRouter.navPathStack

  @Builder pageMap(name: string) {
    if (name === 'SplashPage') {
      SplashPage()
    } else if (name === 'LoginPage') {
      LoginPage()
    } else if (name === 'RegisterPage') {
      RegisterPage()
    } else if (name === 'QuestionnairePage') {
      QuestionnairePage()
    } else if (name === 'HomePage') {
      HomePage()
    } else if (name === 'CategoryFilterPage') {
      CategoryFilterPage()
    } else if (name === 'CompareResultPage') {
      CompareResultPage()
    } else if (name === 'CompareTablePage') {
      CompareTablePage()
    } else if (name === 'ProductDetailPage') {
      ProductDetailPage()
    } else if (name === 'SearchPage') {
      SearchPage()
    } else if (name === 'BrowseHistoryPage') {
      BrowseHistoryPage()
    } else if (name === 'AboutPage') {
      AboutPage()
    } else if (name === 'PrivacyPage') {
      PrivacyPage()
    }
  }

  build() {
    Navigation(this.navPathStack) {
      SplashPage()
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.pageMap)
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}
