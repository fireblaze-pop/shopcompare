import { RatingRecord, ProductMeta } from '../../models/RecommendationModels'
import { RecommendationData } from '../RecommendationData'

export interface RecommendationDataSource {
  getProductMetas(): ProductMeta[]
  getRatings(): RatingRecord[]
  getUsers(): string[]
  getCurrentUserId(): string
}

export class EmbeddedRecommendationDataSource implements RecommendationDataSource {
  getProductMetas(): ProductMeta[] {
    return RecommendationData.getProductMetas()
  }

  getRatings(): RatingRecord[] {
    return RecommendationData.getSampleRatings()
  }

  getUsers(): string[] {
    return RecommendationData.getSampleUsers()
  }

  getCurrentUserId(): string {
    return RecommendationData.getCurrentUserId()
  }
}
