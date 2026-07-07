import { UserAction, RatingEntry, ACTION_VIEW, ACTION_CLICK, ACTION_FAVORITE, ACTION_SEARCH, ACTION_RATE } from '../models/RecommendationModels'
import { UserProfile, Product } from '../models/DataModels'

export interface BehaviorRepository {
  recordView(productId: string): void
  recordClick(productId: string): void
  recordFavorite(productId: string): void
  recordSearch(keyword: string): void
  recordRate(productId: string, rating: number): void
  getActions(): UserAction[]
  getImplicitRatings(): RatingEntry[]
  seedFromProfile(profile: UserProfile, candidates: Product[]): void
  getCurrentUserId(): string
  clearActions(): void
}

class BehaviorStore implements BehaviorRepository {
  private actions: UserAction[] = []
  private currentUserId: string = 'u_me'
  private lastTimestamp: number = 1700000000

  private nextTimestamp(): number {
    this.lastTimestamp = this.lastTimestamp + 1
    return this.lastTimestamp
  }

  recordView(productId: string): void {
    let action: UserAction = {
      productId: productId, actionType: ACTION_VIEW, rating: 0,
      timestamp: this.nextTimestamp(), weight: 1
    }
    this.actions.push(action)
  }

  recordClick(productId: string): void {
    let action: UserAction = {
      productId: productId, actionType: ACTION_CLICK, rating: 0,
      timestamp: this.nextTimestamp(), weight: 2
    }
    this.actions.push(action)
  }

  recordFavorite(productId: string): void {
    let action: UserAction = {
      productId: productId, actionType: ACTION_FAVORITE, rating: 0,
      timestamp: this.nextTimestamp(), weight: 3
    }
    this.actions.push(action)
  }

  recordSearch(keyword: string): void {
    let action: UserAction = {
      productId: keyword, actionType: ACTION_SEARCH, rating: 0,
      timestamp: this.nextTimestamp(), weight: 1
    }
    this.actions.push(action)
  }

  recordRate(productId: string, rating: number): void {
    let action: UserAction = {
      productId: productId, actionType: ACTION_RATE, rating: rating,
      timestamp: this.nextTimestamp(), weight: 5
    }
    this.actions.push(action)
  }

  getActions(): UserAction[] {
    return this.actions
  }

  getImplicitRatings(): RatingEntry[] {
    let entries: RatingEntry[] = []
    let seen: string[] = []
    let i: number = 0
    while (i < this.actions.length) {
      let pid: string = this.actions[i].productId
      if (this.actions[i].actionType === ACTION_SEARCH) {
        i = i + 1
        continue
      }
      let already: boolean = false
      let j: number = 0
      while (j < seen.length) {
        if (seen[j] === pid) {
          already = true
          break
        }
        j = j + 1
      }
      if (!already) {
        seen.push(pid)
      }
      i = i + 1
    }
    let k: number = 0
    while (k < seen.length) {
      let pid: string = seen[k]
      let weight: number = 0
      let explicitRating: number = 0
      let hasExplicit: boolean = false
      let m: number = 0
      while (m < this.actions.length) {
        if (this.actions[m].productId === pid && this.actions[m].actionType !== ACTION_SEARCH) {
          weight = weight + this.actions[m].weight
          if (this.actions[m].actionType === ACTION_RATE) {
            hasExplicit = true
            if (this.actions[m].rating > explicitRating) {
              explicitRating = this.actions[m].rating
            }
          }
        }
        m = m + 1
      }
      let score: number
      if (hasExplicit) {
        score = explicitRating
      } else {
        score = 2 + weight * 0.5
        if (score > 5) {
          score = 5
        }
        if (score < 1) {
          score = 1
        }
      }
      let entry: RatingEntry = { asin: pid, score: score }
      entries.push(entry)
      k = k + 1
    }
    return entries
  }

  seedFromProfile(profile: UserProfile, candidates: Product[]): void {
    if (profile.preferences.length === 0) {
      return
    }
    let seeded: string[] = []
    let i: number = 0
    while (i < candidates.length && seeded.length < 3) {
      let product: Product = candidates[i]
      let match: boolean = false
      let j: number = 0
      while (j < profile.preferences.length) {
        if (product.category === profile.preferences[j]) {
          match = true
          break
        }
        j = j + 1
      }
      if (match) {
        let already: boolean = false
        let m: number = 0
        while (m < seeded.length) {
          if (seeded[m] === product.id) {
            already = true
            break
          }
          m = m + 1
        }
        if (!already) {
          this.recordRate(product.id, 5)
          seeded.push(product.id)
        }
      }
      i = i + 1
    }
  }

  getCurrentUserId(): string {
    return this.currentUserId
  }

  clearActions(): void {
    this.actions = []
  }
}

let store: BehaviorStore = new BehaviorStore()

export class BehaviorManager {
  private static instance: BehaviorStore = store

  static getInstance(): BehaviorStore {
    return store
  }
}
