import { router } from '@kit.ArkUI'
import { Product } from '../models/DataModels'
import { MockData } from '../data/MockData'
import { NavParams, PreferenceManager } from '../utils/PreferenceManager'
import { BehaviorManager } from '../utils/BehaviorManager'
import { DataProvider } from '../data/DataProvider'
import { HttpClient } from '../utils/HttpClient'
import { jsonToProduct } from '../data/repository/RemoteProductRepository'
import { SearchHeader } from '../components/search/SearchHeader'
import { SearchKeywordPanel } from '../components/search/SearchKeywordPanel'
import { SearchResultList } from '../components/search/SearchResultList'

interface SearchApiItem {
  id: string
  name: string
  brand: string
  category: string
  lowest_price: number
  image_url: string
}

interface SearchResult {
  items: SearchApiItem[]
  total: number
}

@Entry
@Component
struct SearchPage {
  @State searchText: string = ''
  @State searchResults: Product[] = []
  @State searchHistory: string[] = []
  @State hotKeywords: string[] = []
  @State showHistory: boolean = true

  private http: HttpClient = DataProvider.getHttpClient()

  aboutToAppear(): void {
    this.hotKeywords = MockData.getHotSearchKeywords()
    this.searchHistory = PreferenceManager.getSearchHistory()
  }

  async doSearch(keyword: string): Promise<void> {
    this.searchText = keyword

    if (keyword.length === 0) {
      this.searchResults = []
      return
    }

    try {
      let resp = await this.http.get(
        '/search?q=' + encodeURIComponent(keyword)
      )

      if (resp.statusCode === 200) {
        let data: SearchResult = JSON.parse(resp.data)
        let products: Product[] = []
        let i: number = 0
        while (i < data.items.length) {
          products.push(jsonToProduct(data.items[i]))
          i = i + 1
        }
        this.searchResults = products
        return
      }
    } catch (e) {
    }

    this.searchLocally(keyword)
  }

  searchLocally(keyword: string): void {
    let allProducts: Product[] = DataProvider.getProductRepository().getProducts()
    let results: Product[] = []
    let i: number = 0

    while (i < allProducts.length) {
      let product: Product = allProducts[i]
      let name: string = product.name.toLowerCase()
      let brand: string = product.brand.toLowerCase()
      let kw: string = keyword.toLowerCase()

      if (
        name.indexOf(kw) >= 0 ||
        brand.indexOf(kw) >= 0
      ) {
        results.push(product)
      }

      i = i + 1
    }

    this.searchResults = results
  }

  commitSearch(keyword: string): void {
    this.doSearch(keyword)

    if (keyword.length > 0) {
      PreferenceManager.addSearchKeyword(keyword)
      BehaviorManager.getInstance().recordSearch(keyword)
      this.searchHistory =
        PreferenceManager.getSearchHistory()
    }
  }

  clearHistory(): void {
    PreferenceManager.clearSearchHistory()
    this.searchHistory =
      PreferenceManager.getSearchHistory()
  }

  navigateToDetail(product: Product): void {
    NavParams.productId = product.id

    router.pushUrl({
      url: 'pages/ProductDetailPage'
    })
  }

  build() {
    Column() {
      SearchHeader({
        searchText: this.searchText,
        onBack: (): void => {
          router.back()
        },
        onTextChange: (value: string): void => {
          this.searchText = value
          this.doSearch(value)
        },
        onSubmit: (): void => {
          this.commitSearch(this.searchText)
        },
        onClear: (): void => {
          this.searchText = ''
          this.searchResults = []
        },
        onSearch: (): void => {
          this.commitSearch(this.searchText)
        }
      })

      if (this.searchResults.length > 0) {
        SearchResultList({
          products: this.searchResults,
          onProductClick: (product: Product): void => {
            this.navigateToDetail(product)
          }
        })
          .layoutWeight(1)
      } else {
        SearchKeywordPanel({
          searchHistory: this.searchHistory,
          hotKeywords: this.hotKeywords,
          showHistory: this.showHistory,
          onToggleHistory: (): void => {
            this.showHistory = !this.showHistory
          },
          onClearHistory: (): void => {
            this.clearHistory()
          },
          onKeywordClick: (keyword: string): void => {
            this.commitSearch(keyword)
          }
        })
          .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
