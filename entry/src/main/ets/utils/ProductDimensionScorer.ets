import { Product } from '../models/DataModels'
import { ProductMeta, RadarDimension } from '../models/RecommendationModels'
import { ProductRepository } from '../data/repository/ProductRepository'

export class ProductDimensionScorer {
  static score(product: Product, meta: ProductMeta | undefined, repo: ProductRepository): RadarDimension[] {
    let dimensions: RadarDimension[] = []
    dimensions.push({ label: '性价比', value: ProductDimensionScorer.costPerformance(product, repo) })
    dimensions.push({ label: '品质', value: ProductDimensionScorer.quality(product) })
    dimensions.push({ label: '品牌', value: ProductDimensionScorer.brand(product, repo) })
    dimensions.push({ label: '售后', value: ProductDimensionScorer.afterSales(product, repo) })
    dimensions.push({ label: '物流', value: ProductDimensionScorer.logistics(product) })
    dimensions.push({ label: '外观', value: ProductDimensionScorer.appearance(product) })
    return dimensions
  }

  private static clamp(value: number): number {
    if (value < 0) {
      return 0
    }
    if (value > 100) {
      return 100
    }
    return value
  }

  private static costPerformance(product: Product, repo: ProductRepository): number {
    let stats = repo.getCategoryPriceStats(product.category)
    let pricePercentile: number = 0.5
    if (stats.max > stats.min) {
      pricePercentile = (product.lowestPrice - stats.min) / (stats.max - stats.min)
    }
    let base: number = 100 - pricePercentile * 50
    let score: number = base * (product.aggregateScore / 10)
    return ProductDimensionScorer.clamp(Math.round(score))
  }

  private static quality(product: Product): number {
    let base: number = product.aggregateRating * 20
    let confidence: number = Math.log10(product.totalReviewCount + 1) / 4
    if (confidence > 1) {
      confidence = 1
    }
    let score: number = base * (0.7 + 0.3 * confidence)
    return ProductDimensionScorer.clamp(Math.round(score))
  }

  private static brand(product: Product, repo: ProductRepository): number {
    let score: number = repo.getBrandReputation(product.brand)
    return ProductDimensionScorer.clamp(Math.round(score))
  }

  private static inStockRate(product: Product): number {
    if (product.platformListings.length === 0) {
      return 1
    }
    let inStockCount: number = 0
    let i: number = 0
    while (i < product.platformListings.length) {
      if (product.platformListings[i].inStock) {
        inStockCount = inStockCount + 1
      }
      i = i + 1
    }
    return inStockCount / product.platformListings.length
  }

  private static afterSales(product: Product, repo: ProductRepository): number {
    let brandScore: number = repo.getBrandReputation(product.brand)
    let stockRate: number = ProductDimensionScorer.inStockRate(product)
    let score: number = brandScore * 0.6 + stockRate * 100 * 0.4
    return ProductDimensionScorer.clamp(Math.round(score))
  }

  private static logistics(product: Product): number {
    let stockRate: number = ProductDimensionScorer.inStockRate(product)
    let score: number = stockRate * 100
    return ProductDimensionScorer.clamp(Math.round(score))
  }

  private static appearance(product: Product): number {
    let base: number = product.aggregateRating * 16
    let boost: number = Math.log(product.totalReviewCount + 1) * 4
    if (boost > 28) {
      boost = 28
    }
    let score: number = base + boost
    return ProductDimensionScorer.clamp(Math.round(score))
  }
}
