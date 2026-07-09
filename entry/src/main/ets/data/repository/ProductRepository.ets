import { Product, Category, FilterSelection } from '../../models/DataModels'
import { MockData } from '../MockData'

export interface PriceStats {
  min: number
  max: number
  avg: number
}

export interface ProductRepository {
  getProducts(): Product[]
  getProductById(id: string): Product | undefined
  getCategories(): Category[]
  getCategoryPriceStats(category: string): PriceStats
  getBrandReputation(brand: string): number
  loadProducts(): Promise<void>
  loadCategories(): Promise<void>
  loadProductDetail(id: string): Promise<Product | undefined>
  loadFilteredProducts(selection: FilterSelection): Promise<void>
}

export class MockProductRepository implements ProductRepository {
  private filteredCache: Product[] = []

  getProducts(): Product[] {
    if (this.filteredCache.length > 0) {
      return this.filteredCache
    }
    return MockData.getProducts()
  }

  getProductById(id: string): Product | undefined {
    let all: Product[] = MockData.getProducts()
    let i: number = 0
    while (i < all.length) {
      if (all[i].id === id) {
        return all[i]
      }
      i = i + 1
    }
    return undefined
  }

  getCategories(): Category[] {
    return MockData.getCategories()
  }

  getCategoryPriceStats(category: string): PriceStats {
    let all: Product[] = MockData.getProducts()
    let prices: number[] = []
    let i: number = 0
    while (i < all.length) {
      if (all[i].category === category) {
        prices.push(all[i].lowestPrice)
      }
      i = i + 1
    }
    if (prices.length === 0) {
      let stats: PriceStats = { min: 0, max: 0, avg: 0 }
      return stats
    }
    let min: number = prices[0]
    let max: number = prices[0]
    let sum: number = 0
    let j: number = 0
    while (j < prices.length) {
      if (prices[j] < min) {
        min = prices[j]
      }
      if (prices[j] > max) {
        max = prices[j]
      }
      sum = sum + prices[j]
      j = j + 1
    }
    let stats: PriceStats = { min: min, max: max, avg: sum / prices.length }
    return stats
  }

  getBrandReputation(brand: string): number {
    if (brand === 'Apple') {
      return 95
    }
    if (brand === '\u534E\u4E3A') {
      return 92
    }
    if (brand === '\u6234\u68EE') {
      return 88
    }
    if (brand === '\u8054\u60F3') {
      return 82
    }
    if (brand === '\u7F8E\u7684') {
      return 80
    }
    if (brand === '\u5170\u853B') {
      return 90
    }
    if (brand === 'Nike') {
      return 86
    }
    if (brand === '\u6234\u5C14') {
      return 80
    }
    if (brand === '\u5C0F\u7C73') {
      return 84
    }
    if (brand === '\u4E09\u661F') {
      return 85
    }
    if (brand === 'OPPO') {
      return 78
    }
    if (brand === 'vivo') {
      return 76
    }
    return 70
  }

  async loadProducts(): Promise<void> {
  }

  async loadCategories(): Promise<void> {
  }

  async loadProductDetail(id: string): Promise<Product | undefined> {
    return this.getProductById(id)
  }

  async loadFilteredProducts(selection: FilterSelection): Promise<void> {
    let all: Product[] = MockData.getProducts()
    let filtered: Product[] = []
    let i: number = 0

    while (i < all.length) {
      let product: Product = all[i]
      let matches: boolean = true

      if (selection.categoryName.length > 0 && product.category !== selection.categoryName) {
        matches = false
      }

      if (matches && selection.brands.length > 0) {
        let brandMatch: boolean = false
        let j: number = 0
        while (j < selection.brands.length) {
          if (product.brand === selection.brands[j]) {
            brandMatch = true
            break
          }
          j = j + 1
        }
        if (!brandMatch) {
          matches = false
        }
      }

      if (matches && selection.minPrice > 0 && product.lowestPrice < selection.minPrice) {
        matches = false
      }

      if (matches && selection.maxPrice > 0 && product.lowestPrice > selection.maxPrice) {
        matches = false
      }

      if (matches) {
        filtered.push(product)
      }
      i = i + 1
    }

    if (selection.sort === 'pricePriority') {
      let a: number = 0
      while (a < filtered.length) {
        let b: number = a + 1
        while (b < filtered.length) {
          if (filtered[a].lowestPrice > filtered[b].lowestPrice) {
            let tmp: Product = filtered[a]
            filtered[a] = filtered[b]
            filtered[b] = tmp
          }
          b = b + 1
        }
        a = a + 1
      }
    }

    this.filteredCache = filtered
  }
}
