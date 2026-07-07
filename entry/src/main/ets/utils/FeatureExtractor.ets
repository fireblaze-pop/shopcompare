import { RatingRecord, ProductMeta, SimilarityEntry } from '../models/RecommendationModels'
import { DataProvider } from '../data/DataProvider'
import { RecommendationDataSource } from '../data/repository/RecommendationDataSource'

interface ItemCount {
  asin: string
  count: number
}

interface PairCount {
  asinA: string
  asinB: string
  count: number
}

interface PairBoost {
  asinA: string
  asinB: string
  boost: number
}

interface SimCache {
  key: string
  value: number
}

interface UserItems {
  userId: string
  items: string[]
}

export class FeatureExtractor {
  private static instance: FeatureExtractor = new FeatureExtractor()
  private itemUserCounts: ItemCount[] = []
  private coOccurrence: PairCount[] = []
  private alsoBuyBoost: PairBoost[] = []
  private metaList: ProductMeta[] = []
  private simCache: SimCache[] = []
  private initialized: boolean = false

  static getInstance(): FeatureExtractor {
    return FeatureExtractor.instance
  }

  isInitialized(): boolean {
    return this.initialized
  }

  init(): void {
    let ds: RecommendationDataSource = DataProvider.getRecommendationDataSource()
    let ratings: RatingRecord[] = ds.getRatings()
    this.metaList = ds.getProductMetas()
    this.buildItemUserCounts(ratings)
    this.buildCoOccurrence(ratings)
    this.buildAlsoBuyBoost(this.metaList)
    this.simCache = []
    this.initialized = true
  }

  getMetaByAsin(asin: string): ProductMeta | undefined {
    let i: number = 0
    while (i < this.metaList.length) {
      if (this.metaList[i].asin === asin) {
        return this.metaList[i]
      }
      i = i + 1
    }
    return undefined
  }

  private buildItemUserCounts(ratings: RatingRecord[]): void {
    this.itemUserCounts = []
    let i: number = 0
    while (i < ratings.length) {
      let asin: string = ratings[i].asin
      let found: boolean = false
      let j: number = 0
      while (j < this.itemUserCounts.length) {
        if (this.itemUserCounts[j].asin === asin) {
          this.itemUserCounts[j].count = this.itemUserCounts[j].count + 1
          found = true
          break
        }
        j = j + 1
      }
      if (!found) {
        let entry: ItemCount = { asin: asin, count: 1 }
        this.itemUserCounts.push(entry)
      }
      i = i + 1
    }
  }

  private buildCoOccurrence(ratings: RatingRecord[]): void {
    let userItems: UserItems[] = []
    let i: number = 0
    while (i < ratings.length) {
      let r: RatingRecord = ratings[i]
      let found: boolean = false
      let j: number = 0
      while (j < userItems.length) {
        if (userItems[j].userId === r.reviewerId) {
          userItems[j].items.push(r.asin)
          found = true
          break
        }
        j = j + 1
      }
      if (!found) {
        let entry: UserItems = { userId: r.reviewerId, items: [r.asin] }
        userItems.push(entry)
      }
      i = i + 1
    }
    this.coOccurrence = []
    let k: number = 0
    while (k < userItems.length) {
      let items: string[] = userItems[k].items
      let a: number = 0
      while (a < items.length) {
        let b: number = a + 1
        while (b < items.length) {
          let asinA: string = items[a]
          let asinB: string = items[b]
          if (asinA > asinB) {
            let tmp: string = asinA
            asinA = asinB
            asinB = tmp
          }
          let found: boolean = false
          let m: number = 0
          while (m < this.coOccurrence.length) {
            if (this.coOccurrence[m].asinA === asinA && this.coOccurrence[m].asinB === asinB) {
              this.coOccurrence[m].count = this.coOccurrence[m].count + 1
              found = true
              break
            }
            m = m + 1
          }
          if (!found) {
            let entry: PairCount = { asinA: asinA, asinB: asinB, count: 1 }
            this.coOccurrence.push(entry)
          }
          b = b + 1
        }
        a = a + 1
      }
      k = k + 1
    }
  }

  private buildAlsoBuyBoost(metas: ProductMeta[]): void {
    this.alsoBuyBoost = []
    let i: number = 0
    while (i < metas.length) {
      let meta: ProductMeta = metas[i]
      let b: number = 0
      while (b < meta.alsoBuy.length) {
        this.addBoost(meta.asin, meta.alsoBuy[b], 1.0)
        b = b + 1
      }
      let v: number = 0
      while (v < meta.alsoView.length) {
        this.addBoost(meta.asin, meta.alsoView[v], 0.5)
        v = v + 1
      }
      i = i + 1
    }
  }

  private addBoost(asinA: string, asinB: string, boost: number): void {
    if (asinA > asinB) {
      let tmp: string = asinA
      asinA = asinB
      asinB = tmp
    }
    let i: number = 0
    while (i < this.alsoBuyBoost.length) {
      if (this.alsoBuyBoost[i].asinA === asinA && this.alsoBuyBoost[i].asinB === asinB) {
        if (boost > this.alsoBuyBoost[i].boost) {
          this.alsoBuyBoost[i].boost = boost
        }
        return
      }
      i = i + 1
    }
    let entry: PairBoost = { asinA: asinA, asinB: asinB, boost: boost }
    this.alsoBuyBoost.push(entry)
  }

  private getCoOccurrence(asinA: string, asinB: string): number {
    let a: string = asinA
    let b: string = asinB
    if (a > b) {
      let tmp: string = a
      a = b
      b = tmp
    }
    let i: number = 0
    while (i < this.coOccurrence.length) {
      if (this.coOccurrence[i].asinA === a && this.coOccurrence[i].asinB === b) {
        return this.coOccurrence[i].count
      }
      i = i + 1
    }
    return 0
  }

  private getBoost(asinA: string, asinB: string): number {
    let a: string = asinA
    let b: string = asinB
    if (a > b) {
      let tmp: string = a
      a = b
      b = tmp
    }
    let i: number = 0
    while (i < this.alsoBuyBoost.length) {
      if (this.alsoBuyBoost[i].asinA === a && this.alsoBuyBoost[i].asinB === b) {
        return this.alsoBuyBoost[i].boost
      }
      i = i + 1
    }
    return 0
  }

  private getItemUserCount(asin: string): number {
    let i: number = 0
    while (i < this.itemUserCounts.length) {
      if (this.itemUserCounts[i].asin === asin) {
        return this.itemUserCounts[i].count
      }
      i = i + 1
    }
    return 0
  }

  itemSimilarity(asinA: string, asinB: string): number {
    if (asinA === asinB) {
      return 1
    }
    let cacheKey: string = asinA + '|' + asinB
    let c: number = 0
    while (c < this.simCache.length) {
      if (this.simCache[c].key === cacheKey) {
        return this.simCache[c].value
      }
      c = c + 1
    }
    let pairCount: number = this.getCoOccurrence(asinA, asinB)
    let countA: number = this.getItemUserCount(asinA)
    let countB: number = this.getItemUserCount(asinB)
    let coScore: number = 0
    if (pairCount > 0 && countA > 0 && countB > 0) {
      coScore = pairCount / Math.sqrt(countA * countB)
    }
    let boost: number = this.getBoost(asinA, asinB)
    let sim: number = coScore * 0.6 + boost * 0.4
    if (sim > 1) {
      sim = 1
    }
    let cache: SimCache = { key: cacheKey, value: sim }
    this.simCache.push(cache)
    let reverseCache: SimCache = { key: asinB + '|' + asinA, value: sim }
    this.simCache.push(reverseCache)
    return sim
  }

  getSimilarItems(asin: string, topN: number): SimilarityEntry[] {
    let result: SimilarityEntry[] = []
    let i: number = 0
    while (i < this.metaList.length) {
      if (this.metaList[i].asin !== asin) {
        let sim: number = this.itemSimilarity(asin, this.metaList[i].asin)
        if (sim > 0) {
          let entry: SimilarityEntry = { id: this.metaList[i].asin, similarity: sim }
          result.push(entry)
        }
      }
      i = i + 1
    }
    result.sort((a: SimilarityEntry, b: SimilarityEntry): number => {
      return b.similarity - a.similarity
    })
    let top: SimilarityEntry[] = []
    let n: number = 0
    while (n < topN && n < result.length) {
      top.push(result[n])
      n = n + 1
    }
    return top
  }

  getAllAsins(): string[] {
    let asins: string[] = []
    let i: number = 0
    while (i < this.metaList.length) {
      asins.push(this.metaList[i].asin)
      i = i + 1
    }
    return asins
  }
}
