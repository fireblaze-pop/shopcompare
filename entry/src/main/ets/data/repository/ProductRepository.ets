import { Product, Category } from '../../models/DataModels'
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
}

export class MockProductRepository implements ProductRepository {
  getProducts(): Product[] {
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
}
