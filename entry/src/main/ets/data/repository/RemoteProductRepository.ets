import { Product, Category, ProductSpec, PricePoint, ReviewTag, SubCategory, PlatformListing } from '../../models/DataModels'
import { ProductRepository, PriceStats, ProductFilterParams } from './ProductRepository'
import { HttpClient } from '../../utils/HttpClient'

interface ProductJson {
  id: string
  name: string
  model_code: string
  brand: string
  category: string
  image_url: string
  description: string
  aggregate_score: number
  aggregate_rating: number
  total_review_count: number
  lowest_price: number
  highest_price: number
  price_spread: number
  historical_low: number
  platform_count: number
  publish_date: string
}

interface ProductDetailJson extends ProductJson {
  specs: ProductSpecJson[]
  platform_listings: PlatformListingJson[]
  price_history: PricePointJson[]
  review_tags: ReviewTagJson[]
}

interface ProductSpecJson {
  key: string
  value: string
}

interface PlatformListingJson {
  platform: string
  price: number
  rating: number
  review_count: number
  in_stock: boolean
  url: string
}

interface PricePointJson {
  date: string
  price: number
}

interface ReviewTagJson {
  text: string
  type: number
  count: number
}

interface ProductListJson {
  total: number
  page: number
  size: number
  items: ProductJson[]
}

interface CategoryJson {
  id: string
  name: string
  icon: string
  sub_categories: SubCategoryJson[]
}

interface SubCategoryJson {
  id: string
  name: string
}

function safeNum(val: number): number {
  if (val === undefined || val === null) {
    return 0
  }
  return val
}

function safeStr(val: string): string {
  if (val === undefined || val === null) {
    return ''
  }
  return val
}

function jsonToProduct(json: ProductJson): Product {
  let product: Product = {
    id: safeStr(json.id),
    name: safeStr(json.name),
    modelCode: safeStr(json.model_code),
    brand: safeStr(json.brand),
    category: safeStr(json.category),
    imageUrl: safeStr(json.image_url),
    specs: [],
    aggregateScore: safeNum(json.aggregate_score),
    aggregateRating: safeNum(json.aggregate_rating),
    totalReviewCount: safeNum(json.total_review_count),
    platformListings: [],
    platformCount: safeNum(json.platform_count),
    lowestPrice: safeNum(json.lowest_price),
    priceSpread: safeNum(json.price_spread),
    historicalLow: safeNum(json.historical_low),
    priceHistory: [],
    reviewTags: [],
    publishDate: safeStr(json.publish_date),
    description: safeStr(json.description)
  }
  return product
}

function jsonToProductDetail(json: ProductDetailJson): Product {
  let product: Product = jsonToProduct(json)

  let listings: PlatformListing[] = []
  let sourceListings: PlatformListingJson[] = []
  if (json.platform_listings !== undefined && json.platform_listings !== null) {
    sourceListings = json.platform_listings
  }
  let i: number = 0
  while (i < sourceListings.length) {
    let pl: PlatformListingJson = sourceListings[i]
    listings.push({
      platform: pl.platform,
      price: pl.price,
      rating: pl.rating,
      reviewCount: pl.review_count,
      inStock: pl.in_stock,
      url: pl.url
    })
    i = i + 1
  }
  product.platformListings = listings
  if (product.platformCount <= 0 && listings.length > 0) {
    product.platformCount = listings.length
  }

  let history: PricePoint[] = []
  let sourceHistory: PricePointJson[] = []
  if (json.price_history !== undefined && json.price_history !== null) {
    sourceHistory = json.price_history
  }
  let h: number = 0
  while (h < sourceHistory.length) {
    history.push({
      date: safeStr(sourceHistory[h].date),
      price: safeNum(sourceHistory[h].price)
    })
    h = h + 1
  }
  history.sort((a: PricePoint, b: PricePoint): number => {
    if (a.date < b.date) {
      return -1
    }
    if (a.date > b.date) {
      return 1
    }
    return 0
  })
  product.priceHistory = history

  let tags: ReviewTag[] = []
  let sourceTags: ReviewTagJson[] = []
  if (json.review_tags !== undefined && json.review_tags !== null) {
    sourceTags = json.review_tags
  }
  let t: number = 0
  while (t < sourceTags.length) {
    tags.push({
      text: safeStr(sourceTags[t].text),
      type: safeNum(sourceTags[t].type),
      count: safeNum(sourceTags[t].count)
    })
    t = t + 1
  }
  product.reviewTags = tags

  let specs: ProductSpec[] = []
  let sourceSpecs: ProductSpecJson[] = []
  if (json.specs !== undefined && json.specs !== null) {
    sourceSpecs = json.specs
  }
  let s: number = 0
  while (s < sourceSpecs.length) {
    specs.push({
      key: safeStr(sourceSpecs[s].key),
      value: safeStr(sourceSpecs[s].value)
    })
    s = s + 1
  }
  product.specs = specs

  return product
}

function jsonToCategory(json: CategoryJson): Category {
  let subCats: SubCategory[] = []
  let i: number = 0
  while (i < json.sub_categories.length) {
    subCats.push({
      id: json.sub_categories[i].id,
      name: json.sub_categories[i].name
    })
    i = i + 1
  }
  return {
    id: json.id,
    name: json.name,
    icon: json.icon,
    subCategories: subCats
  }
}

export class RemoteProductRepository implements ProductRepository {
  private client: HttpClient
  private productCache: Product[]
  private detailCache: Product[]
  private categoryCache: Category[]

  constructor(client: HttpClient) {
    this.client = client
    this.productCache = []
    this.detailCache = []
    this.categoryCache = []
  }

  async refreshAll(): Promise<void> {
    await this.loadProducts()
    await this.loadCategories()
  }

  async loadProducts(): Promise<void> {
    let response = await this.client.get('/products?size=100')
    if (response.statusCode === 200) {
      let data: ProductListJson = JSON.parse(response.data)
      let products: Product[] = []
      let i: number = 0
      while (i < data.items.length) {
        products.push(jsonToProduct(data.items[i]))
        i = i + 1
      }
      this.productCache = products
    }
  }

  async loadCategories(): Promise<void> {
    let response = await this.client.get('/categories')
    if (response.statusCode === 200) {
      let data: CategoryJson[] = JSON.parse(response.data)
      let categories: Category[] = []
      let i: number = 0
      while (i < data.length) {
        categories.push(jsonToCategory(data[i]))
        i = i + 1
      }
      this.categoryCache = categories
    }
  }

  async loadProductDetail(id: string): Promise<Product | undefined> {
    let response = await this.client.get('/products/' + id)
    if (response.statusCode === 200) {
      let data: ProductDetailJson = JSON.parse(response.data)
      let product: Product = jsonToProductDetail(data)
      let found: boolean = false
      let i: number = 0
      while (i < this.detailCache.length) {
        if (this.detailCache[i].id === id) {
          this.detailCache[i] = product
          found = true
          break
        }
        i = i + 1
      }
      if (!found) {
        this.detailCache.push(product)
      }
      this.mergeProductCache([product])
      return product
    }
    return undefined
  }

  async loadFilteredProducts(params: ProductFilterParams): Promise<Product[]> {
    let allProducts: Product[] = []
    let page: number = 1
    let total: number = 0
    let keepLoading: boolean = true

    while (keepLoading) {
      let path: string = this.buildFilterPath(params, page, 100)
      let response = await this.client.get(path)

      if (response.statusCode !== 200) {
        return []
      }

      let data: ProductListJson = JSON.parse(response.data)
      total = data.total

      let pageProducts: Product[] = []
      let i: number = 0
      while (i < data.items.length) {
        let product: Product = jsonToProduct(data.items[i])
        pageProducts.push(product)
        allProducts.push(product)
        i = i + 1
      }

      this.mergeProductCache(pageProducts)

      if (
        data.items.length === 0 ||
        allProducts.length >= total
      ) {
        keepLoading = false
      } else {
        page = page + 1
      }
    }

    return allProducts
  }

  async getFilteredProductCount(params: ProductFilterParams): Promise<number> {
    let path: string = this.buildFilterPath(params, 1, 1)
    let response = await this.client.get(path)

    if (response.statusCode !== 200) {
      return 0
    }

    let data: ProductListJson = JSON.parse(response.data)
    return data.total
  }

  private buildFilterPath(
    params: ProductFilterParams,
    page: number,
    size: number
  ): string {
    let path: string =
      '/products?page=' + page.toString() +
      '&size=' + size.toString()

    if (params.category.length > 0) {
      path = path +
        '&category=' +
        encodeURIComponent(params.category)
    }

    if (params.brands.length > 0) {
      path = path +
        '&brand=' +
        encodeURIComponent(params.brands.join(','))
    }

    if (params.minPrice > 0) {
      path = path +
        '&min_price=' +
        params.minPrice.toString()
    }

    if (params.maxPrice > 0) {
      path = path +
        '&max_price=' +
        params.maxPrice.toString()
    }

    if (params.sort.length > 0) {
      path = path +
        '&sort=' +
        encodeURIComponent(params.sort)
    }

    return path
  }

  private mergeProductCache(products: Product[]): void {
    let i: number = 0

    while (i < products.length) {
      let product: Product = products[i]
      let found: boolean = false
      let j: number = 0

      while (j < this.productCache.length) {
        if (this.productCache[j].id === product.id) {
          this.productCache[j] = product
          found = true
          break
        }
        j = j + 1
      }

      if (!found) {
        this.productCache.push(product)
      }

      i = i + 1
    }
  }

  getProducts(): Product[] {
    return this.productCache
  }

  getProductById(id: string): Product | undefined {
    let i: number = 0
    while (i < this.detailCache.length) {
      if (this.detailCache[i].id === id) {
        return this.detailCache[i]
      }
      i = i + 1
    }
    let j: number = 0
    while (j < this.productCache.length) {
      if (this.productCache[j].id === id) {
        return this.productCache[j]
      }
      j = j + 1
    }
    return undefined
  }

  getCategories(): Category[] {
    return this.categoryCache
  }

  getCategoryPriceStats(category: string): PriceStats {
    return { min: 0, max: 0, avg: 0 }
  }

  getBrandReputation(brand: string): number {
    return 70
  }
}
