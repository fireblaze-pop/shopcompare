import { Product, Category, FilterSelection } from '../../models/DataModels'
import { MockData } from '../MockData'

export interface PriceStats {
  min: number
  max: number
  avg: number
}

export interface ProductFilterParams {
  category: string
  brands: string[]
  minPrice: number
  maxPrice: number
  sort: string
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
  loadFilteredProductsByParams(
    params: ProductFilterParams
  ): Promise<Product[]>
  getFilteredProductCount(
    params: ProductFilterParams
  ): Promise<number>
  clearFilter(): void
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
      let emptyStats: PriceStats = {
        min: 0,
        max: 0,
        avg: 0
      }
      return emptyStats
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

    let stats: PriceStats = {
      min: min,
      max: max,
      avg: sum / prices.length
    }
    return stats
  }

  getBrandReputation(brand: string): number {
    if (brand === 'Apple') {
      return 95
    }
    if (brand === '华为') {
      return 92
    }
    if (brand === '戴森') {
      return 88
    }
    if (brand === '联想') {
      return 82
    }
    if (brand === '美的') {
      return 80
    }
    if (brand === '兰蔻') {
      return 90
    }
    if (brand === 'Nike') {
      return 86
    }
    if (brand === '戴尔') {
      return 80
    }
    if (brand === '小米') {
      return 84
    }
    if (brand === '三星') {
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

  async loadProductDetail(
    id: string
  ): Promise<Product | undefined> {
    return this.getProductById(id)
  }

  async loadFilteredProducts(
    selection: FilterSelection
  ): Promise<void> {
    let params: ProductFilterParams = {
      category: selection.categoryName,
      brands: this.copyStrings(selection.brands),
      minPrice: selection.minPrice,
      maxPrice: selection.maxPrice,
      sort: this.mapSelectionSort(selection.sort)
    }

    this.filteredCache =
      await this.loadFilteredProductsByParams(params)
  }

  async loadFilteredProductsByParams(
    params: ProductFilterParams
  ): Promise<Product[]> {
    let all: Product[] = MockData.getProducts()
    let filtered: Product[] = []
    let i: number = 0

    while (i < all.length) {
      let product: Product = all[i]
      if (this.matchesFilter(product, params)) {
        filtered.push(product)
      }
      i = i + 1
    }

    this.sortProducts(filtered, params.sort)
    this.filteredCache = filtered
    return filtered
  }

  async getFilteredProductCount(
    params: ProductFilterParams
  ): Promise<number> {
    let products: Product[] =
      await this.loadFilteredProductsByParams(params)
    return products.length
  }

  clearFilter(): void {
    this.filteredCache = []
  }

  private matchesFilter(
    product: Product,
    params: ProductFilterParams
  ): boolean {
    if (
      params.category.length > 0 &&
      product.category !== params.category
    ) {
      return false
    }

    if (
      params.brands.length > 0 &&
      params.brands.indexOf(product.brand) < 0
    ) {
      return false
    }

    if (
      params.minPrice > 0 &&
      product.lowestPrice < params.minPrice
    ) {
      return false
    }

    if (
      params.maxPrice > 0 &&
      product.lowestPrice > params.maxPrice
    ) {
      return false
    }

    return true
  }

  private sortProducts(
    products: Product[],
    sort: string
  ): void {
    if (sort === 'price_low') {
      products.sort((a: Product, b: Product): number => {
        return a.lowestPrice - b.lowestPrice
      })
      return
    }

    if (sort === 'rating') {
      products.sort((a: Product, b: Product): number => {
        return b.aggregateRating - a.aggregateRating
      })
      return
    }

    if (sort === 'newest') {
      products.sort((a: Product, b: Product): number => {
        if (a.publishDate < b.publishDate) {
          return 1
        }
        if (a.publishDate > b.publishDate) {
          return -1
        }
        return 0
      })
      return
    }

    products.sort((a: Product, b: Product): number => {
      return b.aggregateScore - a.aggregateScore
    })
  }

  private mapSelectionSort(sort: string): string {
    if (sort === 'pricePriority') {
      return 'price_low'
    }
    if (sort === 'ratingPriority') {
      return 'rating'
    }
    return 'recommend'
  }

  private copyStrings(source: string[]): string[] {
    let result: string[] = []
    let i: number = 0
    while (i < source.length) {
      result.push(source[i])
      i = i + 1
    }
    return result
  }
}
