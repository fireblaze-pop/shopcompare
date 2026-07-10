import { NavRouter } from '../utils/NavRouter'
import { SplashPage } from './SplashPage'
import { LoginPage } from './LoginPage'
import { RegisterPage } from './RegisterPage'
import { QuestionnairePage } from './QuestionnairePage'
import { HomePage } from './HomePage'
import { CategoryFilterPage } from './CategoryFilterPage'
import { CompareResultPage } from './CompareResultPage'
import { CompareTablePage } from './CompareTablePage'
import { ProductDetailPage } from './ProductDetailPage'
import { SearchPage } from './SearchPage'
import { BrowseHistoryPage } from './BrowseHistoryPage'
import { AboutPage } from './AboutPage'
import { PrivacyPage } from './PrivacyPage'

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
