import { Product, PlatformListing } from '../models/DataModels'
import { ProductMeta, RadarDimension } from '../models/RecommendationModels'
import { ProductRepository } from '../data/repository/ProductRepository'

interface DimensionValueSet {
  cost: number
  quality: number
  brand: number
  afterSales: number
  logistics: number
  appearance: number
}

export class ProductDimensionScorer {
  static score(product: Product, meta: ProductMeta | undefined, repo: ProductRepository): RadarDimension[] {
    let values: DimensionValueSet = ProductDimensionScorer.computeValues(product, meta, repo)
    let dimensions: RadarDimension[] = []
    dimensions.push({ label: '性价比', value: values.cost })
    dimensions.push({ label: '品质', value: values.quality })
    dimensions.push({ label: '品牌', value: values.brand })
    dimensions.push({ label: '售后', value: values.afterSales })
    dimensions.push({ label: '物流', value: values.logistics })
    dimensions.push({ label: '外观', value: values.appearance })
    return dimensions
  }

  static overallScore(product: Product, meta: ProductMeta | undefined, repo: ProductRepository): number {
    let values: DimensionValueSet = ProductDimensionScorer.computeValues(product, meta, repo)
    let score: number = 0
    if (product.category === '手机数码') {
      score = values.cost * 0.20 + values.quality * 0.28 + values.brand * 0.20 +
        values.afterSales * 0.12 + values.logistics * 0.08 + values.appearance * 0.12
    } else if (product.category === '电脑办公') {
      score = values.cost * 0.18 + values.quality * 0.30 + values.brand * 0.18 +
        values.afterSales * 0.14 + values.logistics * 0.08 + values.appearance * 0.12
    } else if (product.category === '家用电器') {
      score = values.cost * 0.18 + values.quality * 0.25 + values.brand * 0.15 +
        values.afterSales * 0.24 + values.logistics * 0.12 + values.appearance * 0.06
    } else if (product.category === '美妆个护') {
      score = values.cost * 0.14 + values.quality * 0.24 + values.brand * 0.24 +
        values.afterSales * 0.08 + values.logistics * 0.10 + values.appearance * 0.20
    } else if (product.category === '服饰鞋包') {
      score = values.cost * 0.16 + values.quality * 0.22 + values.brand * 0.20 +
        values.afterSales * 0.08 + values.logistics * 0.10 + values.appearance * 0.24
    } else if (product.category === '食品生鲜') {
      score = values.cost * 0.18 + values.quality * 0.28 + values.brand * 0.12 +
        values.afterSales * 0.08 + values.logistics * 0.24 + values.appearance * 0.10
    } else {
      score = values.cost * 0.18 + values.quality * 0.25 + values.brand * 0.18 +
        values.afterSales * 0.14 + values.logistics * 0.12 + values.appearance * 0.13
    }
    return Math.round(ProductDimensionScorer.clamp(score / 20, 0, 5) * 10) / 10
  }

  private static computeValues(product: Product, meta: ProductMeta | undefined, repo: ProductRepository): DimensionValueSet {
    let rating: number = ProductDimensionScorer.ratingToFive(product.aggregateRating)
    let ratingScore: number = rating / 5 * 100
    let confidence: number = ProductDimensionScorer.clamp(Math.log10(product.totalReviewCount + 1) / 5, 0, 1)
    let stockRate: number = ProductDimensionScorer.inStockRate(product)
    let platformScore: number = ProductDimensionScorer.platformCountScore(product.platformListings.length)
    let brandScore: number = repo.getBrandReputation(product.brand)
    let pricePercentile: number = ProductDimensionScorer.pricePercentile(product, repo)
    let priceRankScore: number = 96 - pricePercentile * 68
    let historyScore: number = ProductDimensionScorer.historyPriceScore(product)
    let spreadBonus: number = ProductDimensionScorer.priceSpreadBonus(product)
    let consistency: number = ProductDimensionScorer.ratingConsistency(product)
    let appearanceBase: number = ProductDimensionScorer.appearanceBase(product, meta)

    let result: DimensionValueSet = {
      cost: ProductDimensionScorer.roundScore(priceRankScore * 0.62 + historyScore * 0.25 + ratingScore * 0.13 + spreadBonus),
      quality: ProductDimensionScorer.roundScore(ratingScore * 0.72 + confidence * 100 * 0.18 + consistency * 0.10),
      brand: ProductDimensionScorer.roundScore(brandScore),
      afterSales: ProductDimensionScorer.roundScore(brandScore * 0.38 + platformScore * 0.32 + stockRate * 100 * 0.20 + confidence * 100 * 0.10),
      logistics: ProductDimensionScorer.roundScore(stockRate * 100 * 0.58 + platformScore * 0.25 + confidence * 100 * 0.17),
      appearance: ProductDimensionScorer.roundScore(appearanceBase * 0.72 + ratingScore * 0.18 + confidence * 100 * 0.10)
    }
    return result
  }

  private static clamp(value: number, low: number, high: number): number {
    if (value < low) {
      return low
    }
    if (value > high) {
      return high
    }
    return value
  }

  private static roundScore(value: number): number {
    return Math.round(ProductDimensionScorer.clamp(value, 0, 100))
  }

  private static ratingToFive(value: number): number {
    if (value <= 0) {
      return 4
    }
    if (value > 5) {
      return ProductDimensionScorer.clamp(value / 2, 0, 5)
    }
    return ProductDimensionScorer.clamp(value, 0, 5)
  }

  private static pricePercentile(product: Product, repo: ProductRepository): number {
    let stats = repo.getCategoryPriceStats(product.category)
    if (stats.max <= stats.min || product.lowestPrice <= 0) {
      return 0.5
    }
    return ProductDimensionScorer.clamp((product.lowestPrice - stats.min) / (stats.max - stats.min), 0, 1)
  }

  private static historyPriceScore(product: Product): number {
    if (product.lowestPrice <= 0 || product.historicalLow <= 0) {
      return 58
    }
    let increaseRatio: number = product.lowestPrice / product.historicalLow - 1
    if (increaseRatio < 0) {
      increaseRatio = 0
    }
    return ProductDimensionScorer.clamp(100 - increaseRatio * 95, 35, 100)
  }

  private static priceSpreadBonus(product: Product): number {
    if (product.lowestPrice <= 0 || product.priceSpread <= 0) {
      return 0
    }
    return ProductDimensionScorer.clamp(product.priceSpread / product.lowestPrice * 120, 0, 10)
  }

  private static platformCountScore(count: number): number {
    if (count <= 0) {
      return 35
    }
    return ProductDimensionScorer.clamp(42 + count * 16, 0, 100)
  }

  private static inStockRate(product: Product): number {
    if (product.platformListings.length === 0) {
      return 0.75
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

  private static ratingConsistency(product: Product): number {
    if (product.platformListings.length < 2) {
      return 78
    }
    let sum: number = 0
    let count: number = 0
    let i: number = 0
    while (i < product.platformListings.length) {
      let listing: PlatformListing = product.platformListings[i]
      if (listing.rating > 0) {
        sum = sum + listing.rating
        count = count + 1
      }
      i = i + 1
    }
    if (count < 2) {
      return 78
    }
    let avg: number = sum / count
    let variance: number = 0
    let j: number = 0
    while (j < product.platformListings.length) {
      let item: PlatformListing = product.platformListings[j]
      if (item.rating > 0) {
        let diff: number = item.rating - avg
        variance = variance + diff * diff
      }
      j = j + 1
    }
    let stddev: number = Math.sqrt(variance / count)
    return ProductDimensionScorer.clamp(100 - stddev * 24, 62, 100)
  }

  private static appearanceBase(product: Product, meta: ProductMeta | undefined): number {
    let imageScore: number = product.imageUrl.length > 10 ? 88 : 42
    let titleRichness: number = ProductDimensionScorer.clamp(product.name.length * 2.1, 30, 100)
    let featureBoost: number = 0
    if (meta !== undefined) {
      featureBoost = ProductDimensionScorer.clamp(meta.feature.length * 4, 0, 12)
    }
    return ProductDimensionScorer.clamp(imageScore * 0.67 + titleRichness * 0.33 + featureBoost, 0, 100)
  }
}
