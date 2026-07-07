import { Product, UserProfile } from './DataModels'

export const ACTION_VIEW: number = 1
export const ACTION_CLICK: number = 2
export const ACTION_FAVORITE: number = 3
export const ACTION_SEARCH: number = 4
export const ACTION_RATE: number = 5

export const SOURCE_USER_CF: string = 'user_cf'
export const SOURCE_ITEM_CF: string = 'item_cf'
export const SOURCE_COLD_START: string = 'cold_start'
export const SOURCE_POPULAR: string = 'popular'

export interface RatingRecord {
  reviewerId: string
  asin: string
  overall: number
  timestamp: number
  helpfulVotes: number
}

export interface ProductMeta {
  asin: string
  title: string
  brand: string
  category: string
  price: number
  feature: string[]
  alsoBuy: string[]
  alsoView: string[]
  description: string
}

export interface UserAction {
  productId: string
  actionType: number
  rating: number
  timestamp: number
  weight: number
}

export interface RatingEntry {
  asin: string
  score: number
}

export interface UserVector {
  userId: string
  ratings: RatingEntry[]
}

export interface SimilarityEntry {
  id: string
  similarity: number
}

export interface RecommendationItem {
  product: Product
  score: number
  reason: string
  source: string
}

export interface RecommendationContext {
  userId: string
  actions: UserAction[]
  profile: UserProfile
}

export interface RadarDimension {
  label: string
  value: number
}

export interface RadarPoint {
  x: number
  y: number
}
