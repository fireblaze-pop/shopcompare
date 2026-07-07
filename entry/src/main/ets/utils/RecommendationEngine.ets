import { RatingRecord, RatingEntry, UserVector, SimilarityEntry, RecommendationItem, UserAction } from '../models/RecommendationModels'
import { SOURCE_USER_CF, SOURCE_ITEM_CF, SOURCE_COLD_START, SOURCE_POPULAR, ACTION_VIEW, ACTION_CLICK, ACTION_FAVORITE, ACTION_RATE, ACTION_SEARCH } from '../models/RecommendationModels'
import { Product, UserProfile } from '../models/DataModels'
import { DataProvider } from '../data/DataProvider'
import { ProductRepository } from '../data/repository/ProductRepository'
import { RecommendationDataSource } from '../data/repository/RecommendationDataSource'
import { BehaviorRepository } from './BehaviorManager'
import { FeatureExtractor } from './FeatureExtractor'
import { PreferenceManager } from './PreferenceManager'

interface CandidateItem {
  asin: string
  weightedSum: number
  simSum: number
}

interface ItemCFCandidate {
  asin: string
  score: number
  sourceAsin: string
}

interface MergedCandidate {
  asin: string
  score: number
  reason: string
  source: string
  priority: number
}

export class RecommendationEngine {
  private static instance: RecommendationEngine = new RecommendationEngine()
  private matrix: UserVector[] = []
  private initialized: boolean = false

  static getInstance(): RecommendationEngine {
    return RecommendationEngine.instance
  }

  isInitialized(): boolean {
    return this.initialized
  }

  init(): void {
    if (!FeatureExtractor.getInstance().isInitialized()) {
      FeatureExtractor.getInstance().init()
    }
    this.rebuildMatrix()
    this.initialized = true
  }

  refresh(): void {
    this.rebuildMatrix()
  }

  private rebuildMatrix(): void {
    let ds: RecommendationDataSource = DataProvider.getRecommendationDataSource()
    let ratings: RatingRecord[] = ds.getRatings()
    let behavior: BehaviorRepository = DataProvider.getBehaviorRepository()
    let currentUserId: string = behavior.getCurrentUserId()
    this.matrix = []
    let i: number = 0
    while (i < ratings.length) {
      let r: RatingRecord = ratings[i]
      if (r.reviewerId !== currentUserId) {
        let found: boolean = false
        let j: number = 0
        while (j < this.matrix.length) {
          if (this.matrix[j].userId === r.reviewerId) {
            let entry: RatingEntry = { asin: r.asin, score: r.overall }
            this.matrix[j].ratings.push(entry)
            found = true
            break
          }
          j = j + 1
        }
        if (!found) {
          let uv: UserVector = { userId: r.reviewerId, ratings: [{ asin: r.asin, score: r.overall }] }
          this.matrix.push(uv)
        }
      }
      i = i + 1
    }
    let implicit: RatingEntry[] = behavior.getImplicitRatings()
    let currentVec: UserVector = { userId: currentUserId, ratings: implicit }
    this.matrix.push(currentVec)
  }

  private getUserVector(userId: string): UserVector | undefined {
    let i: number = 0
    while (i < this.matrix.length) {
      if (this.matrix[i].userId === userId) {
        return this.matrix[i]
      }
      i = i + 1
    }
    return undefined
  }

  private userSimilarity(uA: UserVector, uB: UserVector): number {
    let dot: number = 0
    let normA: number = 0
    let normB: number = 0
    let a: number = 0
    while (a < uA.ratings.length) {
      normA = normA + uA.ratings[a].score * uA.ratings[a].score
      let b: number = 0
      while (b < uB.ratings.length) {
        if (uB.ratings[b].asin === uA.ratings[a].asin) {
          dot = dot + uA.ratings[a].score * uB.ratings[b].score
        }
        b = b + 1
      }
      a = a + 1
    }
    let c: number = 0
    while (c < uB.ratings.length) {
      normB = normB + uB.ratings[c].score * uB.ratings[c].score
      c = c + 1
    }
    if (normA === 0 || normB === 0) {
      return 0
    }
    return dot / (Math.sqrt(normA) * Math.sqrt(normB))
  }

  private isRatedByUser(vec: UserVector, asin: string): boolean {
    let i: number = 0
    while (i < vec.ratings.length) {
      if (vec.ratings[i].asin === asin) {
        return true
      }
      i = i + 1
    }
    return false
  }

  userBasedCF(userId: string, topN: number): RecommendationItem[] {
    let currentUser: UserVector | undefined = this.getUserVector(userId)
    if (currentUser === undefined || currentUser.ratings.length === 0) {
      return []
    }
    let sims: SimilarityEntry[] = []
    let i: number = 0
    while (i < this.matrix.length) {
      if (this.matrix[i].userId !== userId) {
        let s: number = this.userSimilarity(currentUser, this.matrix[i])
        if (s > 0) {
          let entry: SimilarityEntry = { id: this.matrix[i].userId, similarity: s }
          sims.push(entry)
        }
      }
      i = i + 1
    }
    sims.sort((a: SimilarityEntry, b: SimilarityEntry): number => {
      return b.similarity - a.similarity
    })
    let K: number = 8
    let candidates: CandidateItem[] = []
    let k: number = 0
    while (k < K && k < sims.length) {
      let simUser: UserVector | undefined = this.getUserVector(sims[k].id)
      if (simUser === undefined) {
        k = k + 1
        continue
      }
      let sim: number = sims[k].similarity
      let m: number = 0
      while (m < simUser.ratings.length) {
        let asin: string = simUser.ratings[m].asin
        if (!this.isRatedByUser(currentUser, asin) && simUser.ratings[m].score >= 4) {
          let found: boolean = false
          let p: number = 0
          while (p < candidates.length) {
            if (candidates[p].asin === asin) {
              candidates[p].weightedSum = candidates[p].weightedSum + sim * simUser.ratings[m].score
              candidates[p].simSum = candidates[p].simSum + sim
              found = true
              break
            }
            p = p + 1
          }
          if (!found) {
            let c: CandidateItem = { asin: asin, weightedSum: sim * simUser.ratings[m].score, simSum: sim }
            candidates.push(c)
          }
        }
        m = m + 1
      }
      k = k + 1
    }
    let result: RecommendationItem[] = []
    let repo: ProductRepository = DataProvider.getProductRepository()
    let q: number = 0
    while (q < candidates.length) {
      let predicted: number = candidates[q].simSum > 0 ? candidates[q].weightedSum / candidates[q].simSum : 0
      let product: Product | undefined = repo.getProductById(candidates[q].asin)
      if (product !== undefined && predicted >= 3) {
        let item: RecommendationItem = {
          product: product, score: predicted, reason: '和你品味相似的用户也在看', source: SOURCE_USER_CF
        }
        result.push(item)
      }
      q = q + 1
    }
    result.sort((a: RecommendationItem, b: RecommendationItem): number => {
      return b.score - a.score
    })
    return this.takeTop(result, topN)
  }

  itemBasedCF(userId: string, topN: number): RecommendationItem[] {
    let currentUser: UserVector | undefined = this.getUserVector(userId)
    if (currentUser === undefined || currentUser.ratings.length === 0) {
      return []
    }
    let extractor: FeatureExtractor = FeatureExtractor.getInstance()
    let repo: ProductRepository = DataProvider.getProductRepository()
    let candidates: ItemCFCandidate[] = []
    let i: number = 0
    while (i < currentUser.ratings.length) {
      if (currentUser.ratings[i].score >= 3) {
        let sourceAsin: string = currentUser.ratings[i].asin
        let likedScore: number = currentUser.ratings[i].score
        let sims: SimilarityEntry[] = extractor.getSimilarItems(sourceAsin, 6)
        let j: number = 0
        while (j < sims.length) {
          let asin: string = sims[j].id
          if (!this.isRatedByUser(currentUser, asin)) {
            let score: number = sims[j].similarity * likedScore
            let found: boolean = false
            let p: number = 0
            while (p < candidates.length) {
              if (candidates[p].asin === asin) {
                if (score > candidates[p].score) {
                  candidates[p].score = score
                  candidates[p].sourceAsin = sourceAsin
                }
                found = true
                break
              }
              p = p + 1
            }
            if (!found) {
              let c: ItemCFCandidate = { asin: asin, score: score, sourceAsin: sourceAsin }
              candidates.push(c)
            }
          }
          j = j + 1
        }
      }
      i = i + 1
    }
    let result: RecommendationItem[] = []
    let q: number = 0
    while (q < candidates.length) {
      let product: Product | undefined = repo.getProductById(candidates[q].asin)
      let sourceProduct: Product | undefined = repo.getProductById(candidates[q].sourceAsin)
      if (product !== undefined && sourceProduct !== undefined && candidates[q].score >= 1) {
        let item: RecommendationItem = {
          product: product, score: candidates[q].score,
          reason: '与「' + sourceProduct.name + '」相似', source: SOURCE_ITEM_CF
        }
        result.push(item)
      }
      q = q + 1
    }
    result.sort((a: RecommendationItem, b: RecommendationItem): number => {
      return b.score - a.score
    })
    return this.takeTop(result, topN)
  }

  coldStart(profile: UserProfile, topN: number): RecommendationItem[] {
    let repo: ProductRepository = DataProvider.getProductRepository()
    let all: Product[] = repo.getProducts()
    let result: RecommendationItem[] = []
    let i: number = 0
    while (i < all.length) {
      let product: Product = all[i]
      let match: boolean = false
      if (profile.preferences.length > 0) {
        let j: number = 0
        while (j < profile.preferences.length) {
          if (product.category === profile.preferences[j]) {
            match = true
            break
          }
          j = j + 1
        }
      } else {
        match = true
      }
      if (match && this.matchesBudget(product.lowestPrice, profile.budget)) {
        let reason: string = profile.preferences.length > 0 ? '根据你的' + profile.preferences[0] + '偏好' : '为你精选'
        let item: RecommendationItem = {
          product: product, score: product.aggregateScore, reason: reason, source: SOURCE_COLD_START
        }
        result.push(item)
      }
      i = i + 1
    }
    result.sort((a: RecommendationItem, b: RecommendationItem): number => {
      return b.score - a.score
    })
    return this.takeTop(result, topN)
  }

  private matchesBudget(price: number, budget: string): boolean {
    if (budget.length === 0) {
      return true
    }
    if (budget === 'thrifty') {
      return price < 1000
    }
    if (budget === 'balanced') {
      return price >= 1000 && price < 5000
    }
    if (budget === 'quality') {
      return price >= 5000 && price < 10000
    }
    if (budget === 'premium') {
      return price >= 10000
    }
    return true
  }

  popularFallback(topN: number): RecommendationItem[] {
    let repo: ProductRepository = DataProvider.getProductRepository()
    let all: Product[] = repo.getProducts()
    let result: RecommendationItem[] = []
    let i: number = 0
    while (i < all.length) {
      let product: Product = all[i]
      let score: number = product.aggregateScore * Math.log(product.totalReviewCount + 1)
      let item: RecommendationItem = {
        product: product, score: score, reason: '热门好物', source: SOURCE_POPULAR
      }
      result.push(item)
      i = i + 1
    }
    result.sort((a: RecommendationItem, b: RecommendationItem): number => {
      return b.score - a.score
    })
    return this.takeTop(result, topN)
  }

  private getExcludedAsins(): string[] {
    let behavior: BehaviorRepository = DataProvider.getBehaviorRepository()
    let actions: UserAction[] = behavior.getActions()
    let excluded: string[] = []
    let i: number = 0
    while (i < actions.length) {
      if (actions[i].actionType !== ACTION_SEARCH) {
        let already: boolean = false
        let j: number = 0
        while (j < excluded.length) {
          if (excluded[j] === actions[i].productId) {
            already = true
            break
          }
          j = j + 1
        }
        if (!already) {
          excluded.push(actions[i].productId)
        }
      }
      i = i + 1
    }
    return excluded
  }

  private mergeCandidates(lists: RecommendationItem[][], priorities: number[]): MergedCandidate[] {
    let merged: MergedCandidate[] = []
    let l: number = 0
    while (l < lists.length) {
      let list: RecommendationItem[] = lists[l]
      let priority: number = priorities[l]
      let m: number = 0
      while (m < list.length) {
        let item: RecommendationItem = list[m]
        let found: boolean = false
        let p: number = 0
        while (p < merged.length) {
          if (merged[p].asin === item.product.id) {
            if (priority > merged[p].priority ||
              (priority === merged[p].priority && item.score > merged[p].score)) {
              merged[p].score = item.score
              merged[p].reason = item.reason
              merged[p].source = item.source
              merged[p].priority = priority
            }
            found = true
            break
          }
          p = p + 1
        }
        if (!found) {
          let mc: MergedCandidate = {
            asin: item.product.id, score: item.score, reason: item.reason,
            source: item.source, priority: priority
          }
          merged.push(mc)
        }
        m = m + 1
      }
      l = l + 1
    }
    return merged
  }

  recommend(topN: number): RecommendationItem[] {
    let behavior: BehaviorRepository = DataProvider.getBehaviorRepository()
    let userId: string = behavior.getCurrentUserId()
    let implicitCount: number = behavior.getImplicitRatings().length
    let profile: UserProfile = PreferenceManager.loadUserProfile()
    let userCFList: RecommendationItem[] = []
    let itemCFList: RecommendationItem[] = []
    let coldList: RecommendationItem[] = []
    let popularList: RecommendationItem[] = this.popularFallback(topN)
    let lists: RecommendationItem[][] = []
    let priorities: number[] = []
    if (implicitCount < 3) {
      coldList = this.coldStart(profile, topN)
      lists = [coldList, popularList]
      priorities = [2, 1]
    } else if (implicitCount < 8) {
      itemCFList = this.itemBasedCF(userId, topN)
      userCFList = this.userBasedCF(userId, topN)
      coldList = this.coldStart(profile, topN)
      lists = [itemCFList, userCFList, coldList, popularList]
      priorities = [3, 4, 2, 1]
    } else {
      userCFList = this.userBasedCF(userId, topN)
      itemCFList = this.itemBasedCF(userId, topN)
      lists = [userCFList, itemCFList, popularList]
      priorities = [4, 3, 1]
    }
    let merged: MergedCandidate[] = this.mergeCandidates(lists, priorities)
    merged.sort((a: MergedCandidate, b: MergedCandidate): number => {
      return b.score - a.score
    })
    let excluded: string[] = this.getExcludedAsins()
    let repo: ProductRepository = DataProvider.getProductRepository()
    let result: RecommendationItem[] = []
    let i: number = 0
    while (i < merged.length && result.length < topN) {
      let mc: MergedCandidate = merged[i]
      let isExcluded: boolean = false
      let j: number = 0
      while (j < excluded.length) {
        if (excluded[j] === mc.asin) {
          isExcluded = true
          break
        }
        j = j + 1
      }
      if (!isExcluded) {
        let product: Product | undefined = repo.getProductById(mc.asin)
        if (product !== undefined) {
          let item: RecommendationItem = {
            product: product, score: mc.score, reason: mc.reason, source: mc.source
          }
          result.push(item)
        }
      }
      i = i + 1
    }
    let k: number = 0
    while (result.length < topN && k < popularList.length) {
      let already: boolean = false
      let m: number = 0
      while (m < result.length) {
        if (result[m].product.id === popularList[k].product.id) {
          already = true
          break
        }
        m = m + 1
      }
      let isExcluded: boolean = false
      let n: number = 0
      while (n < excluded.length) {
        if (excluded[n] === popularList[k].product.id) {
          isExcluded = true
          break
        }
        n = n + 1
      }
      if (!already && !isExcluded) {
        result.push(popularList[k])
      }
      k = k + 1
    }
    return result
  }

  getSimilarProducts(asin: string, topN: number): RecommendationItem[] {
    let extractor: FeatureExtractor = FeatureExtractor.getInstance()
    let repo: ProductRepository = DataProvider.getProductRepository()
    let sourceProduct: Product | undefined = repo.getProductById(asin)
    if (sourceProduct === undefined) {
      return []
    }
    let sims: SimilarityEntry[] = extractor.getSimilarItems(asin, topN)
    let result: RecommendationItem[] = []
    let i: number = 0
    while (i < sims.length) {
      let product: Product | undefined = repo.getProductById(sims[i].id)
      if (product !== undefined) {
        let item: RecommendationItem = {
          product: product, score: sims[i].similarity,
          reason: '与「' + sourceProduct.name + '」相似', source: SOURCE_ITEM_CF
        }
        result.push(item)
      }
      i = i + 1
    }
    return result
  }

  private takeTop(list: RecommendationItem[], topN: number): RecommendationItem[] {
    let top: RecommendationItem[] = []
    let i: number = 0
    while (i < topN && i < list.length) {
      top.push(list[i])
      i = i + 1
    }
    return top
  }
}
