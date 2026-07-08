import { ProductRepository, MockProductRepository } from './repository/ProductRepository'
import { RemoteProductRepository } from './repository/RemoteProductRepository'
import { RecommendationDataSource, EmbeddedRecommendationDataSource } from './repository/RecommendationDataSource'
import { BehaviorRepository, BehaviorManager } from '../utils/BehaviorManager'
import { HttpClient } from '../utils/HttpClient'

let sharedHttpClient: HttpClient = new HttpClient()

export class DataProvider {
  private static mockRepo: MockProductRepository = new MockProductRepository()
  private static remoteRepo: RemoteProductRepository = new RemoteProductRepository(sharedHttpClient)
  private static productRepo: ProductRepository = DataProvider.remoteRepo
  private static recDataSource: RecommendationDataSource = new EmbeddedRecommendationDataSource()
  private static behaviorRepo: BehaviorRepository = BehaviorManager.getInstance()
  private static remoteLoaded: boolean = false

  static getHttpClient(): HttpClient {
    return sharedHttpClient
  }

  static getProductRepository(): ProductRepository {
    if (!DataProvider.remoteLoaded) {
      DataProvider.remoteLoaded = true
      DataProvider.tryLoadRemote()
    }
    return DataProvider.productRepo
  }

  static getRecommendationDataSource(): RecommendationDataSource {
    return DataProvider.recDataSource
  }

  static getBehaviorRepository(): BehaviorRepository {
    return DataProvider.behaviorRepo
  }

  private static async tryLoadRemote(): Promise<void> {
    try {
      let response = await sharedHttpClient.get('/products?size=1')
      if (response.statusCode === 200) {
        await DataProvider.remoteRepo.refreshAll()
        if (DataProvider.remoteRepo.getProducts().length === 0) {
          DataProvider.productRepo = DataProvider.mockRepo
        }
      } else {
        DataProvider.productRepo = DataProvider.mockRepo
      }
    } catch (e) {
      DataProvider.productRepo = DataProvider.mockRepo
    }
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
}
