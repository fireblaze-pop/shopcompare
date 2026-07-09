/*
 * ShopCompare v0.3 — Frontend Data Layer Full Tests (Layer 3)
 * Tests MockProductRepository, DataModels, DataProvider, ProductPlaceholder.
 * Uses @ohos/hypium test framework.
 */
import { describe, it, expect } from '@ohos/hypium'
import { Product, Category, ProductSpec, PlatformListing, PricePoint, ReviewTag } from '../../../main/ets/models/DataModels'
import { MockProductRepository, ProductRepository, PriceStats } from '../../../main/ets/data/repository/ProductRepository'
import { DataProvider } from '../../../main/ets/data/DataProvider'
import { MockData } from '../../../main/ets/data/MockData'
import { HttpClient } from '../../../main/ets/utils/HttpClient'
import { ProductPlaceholder } from '../../../main/ets/components/ProductCard'

export default function dataLayerFullTest() {

  describe('DataLayerFullTest', () => {

    /*
     * U1: MockProductRepository returns 30 products
     */
    it('U1_MockProductRepository_getProducts_returns_30', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let products: Product[] = repo.getProducts()
      expect(products.length).assertEqual(30)
    })

    /*
     * U2: All products have non-empty category in valid set
     */
    it('U2_All_products_have_valid_category', 0, () => {
      let validCats: string[] = [
        '\u624B\u673A\u6570\u7801', '\u7535\u8111\u529E\u516C', '\u5BB6\u7528\u7535\u5668',
        '\u7F8E\u5986\u4E2A\u62A4', '\u670D\u9970\u978B\u5305', '\u98DF\u54C1\u751F\u9C9C'
      ]
      let repo: MockProductRepository = new MockProductRepository()
      let products: Product[] = repo.getProducts()
      let allValid: boolean = true
      let i: number = 0
      while (i < products.length) {
        let found: boolean = false
        let j: number = 0
        while (j < validCats.length) {
          if (products[i].category === validCats[j]) {
            found = true
            break
          }
          j = j + 1
        }
        if (!found) {
          allValid = false
          break
        }
        i = i + 1
      }
      expect(allValid).assertTrue()
    })

    /*
     * U3: All products have 2+ platform listings
     */
    it('U3_All_products_have_2plus_platforms', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let products: Product[] = repo.getProducts()
      let allOk: boolean = true
      let i: number = 0
      while (i < products.length) {
        if (products[i].platformListings.length < 2) {
          allOk = false
          break
        }
        i = i + 1
      }
      expect(allOk).assertTrue()
    })

    /*
     * U4: All products have lowestPrice > 0
     */
    it('U4_All_products_have_positive_lowest_price', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let products: Product[] = repo.getProducts()
      let allPositive: boolean = true
      let i: number = 0
      while (i < products.length) {
        if (products[i].lowestPrice <= 0) {
          allPositive = false
          break
        }
        i = i + 1
      }
      expect(allPositive).assertTrue()
    })

    /*
     * U5: All products have priceSpread >= 0
     */
    it('U5_All_products_have_non_negative_spread', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let products: Product[] = repo.getProducts()
      let allOk: boolean = true
      let i: number = 0
      while (i < products.length) {
        if (products[i].priceSpread < 0) {
          allOk = false
          break
        }
        i = i + 1
      }
      expect(allOk).assertTrue()
    })

    /*
     * U6: loadFilteredProducts filters by category correctly
     */
    it('U6_loadFilteredProducts_filters_by_category', 1, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let result: boolean = false
      let checkFn = (): void => {
        repo.loadFilteredProducts('\u624B\u673A\u6570\u7801', '', 'recommend').then(() => {
          let filtered: Product[] = repo.getProducts()
          let allMatch: boolean = true
          let i: number = 0
          while (i < filtered.length) {
            if (filtered[i].category !== '\u624B\u673A\u6570\u7801') {
              allMatch = false
              break
            }
            i = i + 1
          }
          expect(allMatch).assertTrue()
          expect(filtered.length > 0).assertTrue()
        })
      }
      checkFn()
    })

    /*
     * U7: loadFilteredProducts filters by brand correctly
     */
    it('U7_loadFilteredProducts_filters_by_brand', 1, () => {
      let repo: MockProductRepository = new MockProductRepository()
      repo.loadFilteredProducts('\u624B\u673A\u6570\u7801', 'Apple', 'recommend').then(() => {
        let filtered: Product[] = repo.getProducts()
        let allMatch: boolean = true
        let i: number = 0
        while (i < filtered.length) {
          if (filtered[i].brand !== 'Apple') {
            allMatch = false
            break
          }
          i = i + 1
        }
        expect(allMatch).assertTrue()
      })
    })

    /*
     * U8: loadFilteredProducts cross-category returns empty
     */
    it('U8_loadFilteredProducts_cross_category_empty', 1, () => {
      let repo: MockProductRepository = new MockProductRepository()
      repo.loadFilteredProducts('\u98DF\u54C1\u751F\u9C9C', 'Apple', 'recommend').then(() => {
        let filtered: Product[] = repo.getProducts()
        expect(filtered.length).assertEqual(0)
      })
    })

    /*
     * U9: getCategoryPriceStats returns valid range
     */
    it('U9_getCategoryPriceStats_valid_range', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let stats: PriceStats = repo.getCategoryPriceStats('\u624B\u673A\u6570\u7801')
      expect(stats.min > 0).assertTrue()
      expect(stats.max >= stats.min).assertTrue()
      expect(stats.avg > 0).assertTrue()
    })

    /*
     * U10: getBrandReputation Apple = 95
     */
    it('U10_getBrandReputation_Apple_95', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let score: number = repo.getBrandReputation('Apple')
      expect(score).assertEqual(95)
    })

    /*
     * U11: getBrandReputation unknown = 70
     */
    it('U11_getBrandReputation_unknown_70', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let score: number = repo.getBrandReputation('UnknownBrandXYZ')
      expect(score).assertEqual(70)
    })

    /*
     * U12: getCategories returns 6
     */
    it('U12_getCategories_returns_6', 0, () => {
      let categories: Category[] = MockData.getCategories()
      expect(categories.length).assertEqual(6)
      let i: number = 0
      while (i < categories.length) {
        expect(categories[i].name.length > 0).assertTrue()
        expect(categories[i].icon.length > 0).assertTrue()
        expect(categories[i].subCategories.length >= 2).assertTrue()
        i = i + 1
      }
    })

    /*
     * U13: DataProvider has init method and HttpClient
     */
    it('U13_DataProvider_has_init_and_httpclient', 0, () => {
      let hasInit: boolean = typeof DataProvider.init === 'function'
      let hasClient: boolean = DataProvider.getHttpClient() instanceof HttpClient
      let hasRepo: boolean = DataProvider.getProductRepository() !== undefined
      expect(hasInit).assertTrue()
      expect(hasClient).assertTrue()
      expect(hasRepo).assertTrue()
    })

    /*
     * U14: getProductById works
     */
    it('U14_getProductById_works', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let products: Product[] = repo.getProducts()
      if (products.length > 0) {
        let firstId: string = products[0].id
        let found: Product | undefined = repo.getProductById(firstId)
        expect(found !== undefined).assertTrue()
        if (found !== undefined) {
          expect(found.id).assertEqual(firstId)
        }
      } else {
        expect(true).assertTrue()
      }
    })

    /*
     * U15: loadFilteredProducts sorts by price ascending
     */
    it('U15_loadFilteredProducts_sorts_by_price', 1, () => {
      let repo: MockProductRepository = new MockProductRepository()
      repo.loadFilteredProducts('', '', 'pricePriority').then(() => {
        let sorted: Product[] = repo.getProducts()
        let isAscending: boolean = true
        let i: number = 0
        while (i < sorted.length - 1) {
          if (sorted[i].lowestPrice > sorted[i + 1].lowestPrice) {
            isAscending = false
            break
          }
          i = i + 1
        }
        expect(isAscending).assertTrue()
      })
    })

    /*
     * U16: ProductPlaceholder builder function exists
     */
    it('U16_ProductPlaceholder_exists', 0, () => {
      let isFunction: boolean = typeof ProductPlaceholder === 'function'
      expect(isFunction).assertTrue()
    })

    /*
     * U17: MockData getProducts returns array
     */
    it('U17_MockData_getProducts_returns_array', 0, () => {
      let products: Product[] = MockData.getProducts()
      expect(products.length > 0).assertTrue()
    })

    /*
     * U18: MockData products have non-empty name and brand
     */
    it('U18_Products_have_name_and_brand', 0, () => {
      let repo: MockProductRepository = new MockProductRepository()
      let products: Product[] = repo.getProducts()
      let allOk: boolean = true
      let i: number = 0
      while (i < products.length) {
        if (products[i].name.length === 0 || products[i].brand.length === 0) {
          allOk = false
          break
        }
        i = i + 1
      }
      expect(allOk).assertTrue()
    })

  })

}
