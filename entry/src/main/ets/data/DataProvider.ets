import { ProductRepository, MockProductRepository } from './repository/ProductRepository'
import { RemoteProductRepository } from './repository/RemoteProductRepository'
import { RecommendationDataSource, EmbeddedRecommendationDataSource } from './repository/RecommendationDataSource'
import { BehaviorRepository, BehaviorManager } from '../utils/BehaviorManager'
import { HttpClient } from '../utils/HttpClient'

let sharedHttpClient: HttpClient = new HttpClient()

export class DataProvider {
  private static productRepo: ProductRepository = new MockProductRepository()
  private static recDataSource: RecommendationDataSource = new EmbeddedRecommendationDataSource()
  private static behaviorRepo: BehaviorRepository = BehaviorManager.getInstance()
  private static remoteRepo: RemoteProductRepository = new RemoteProductRepository(sharedHttpClient)

  static getHttpClient(): HttpClient {
    return sharedHttpClient
  }

  static getProductRepository(): ProductRepository {
    return DataProvider.productRepo
  }

  static getRecommendationDataSource(): RecommendationDataSource {
    return DataProvider.recDataSource
  }

  static getBehaviorRepository(): BehaviorRepository {
    return DataProvider.behaviorRepo
  }

  static switchToRemote(): void {
    DataProvider.productRepo = DataProvider.remoteRepo
  }

  static switchToMock(): void {
    DataProvider.productRepo = new MockProductRepository()
  }

  static switchToCrawlerRepositories(productRepo: ProductRepository, recDataSource: RecommendationDataSource,
    behaviorRepo: BehaviorRepository): void {
    DataProvider.productRepo = productRepo
    DataProvider.recDataSource = recDataSource
    DataProvider.behaviorRepo = behaviorRepo
  }

  static async init(): Promise<void> {
    try {
      let response = await sharedHttpClient.get('/products?size=1')
      if (response.statusCode === 200) {
        DataProvider.productRepo = DataProvider.remoteRepo
        await DataProvider.remoteRepo.refreshAll()
      }
    } catch (e) {
    }
  }
}
