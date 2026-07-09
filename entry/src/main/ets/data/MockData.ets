import { Category, Product, PlatformListing, ProductSpec, PricePoint, ReviewTag, FilterGroup } from '../models/DataModels'

function createProduct(
  id: string,
  name: string,
  modelCode: string,
  brand: string,
  category: string,
  lowestPrice: number,
  aggregateScore: number,
  aggregateRating: number,
  totalReviewCount: number,
  priceSpread: number,
  historicalLow: number,
  description: string
): Product {
  let specs: ProductSpec[] = [
    { key: '品牌', value: brand },
    { key: '型号', value: modelCode }
  ]
  let platforms: PlatformListing[] = [
    { platform: '京东', price: lowestPrice, rating: 4.5, reviewCount: 1200, inStock: true, url: '' },
    { platform: '天猫', price: lowestPrice + priceSpread, rating: 4.3, reviewCount: 800, inStock: true, url: '' }
  ]
  let priceHistory: PricePoint[] = [
    { date: '2026-06-01', price: historicalLow + 50 },
    { date: '2026-06-15', price: historicalLow },
    { date: '2026-07-01', price: lowestPrice }
  ]
  let reviewTags: ReviewTag[] = [
    { text: '性价比高', type: 1, count: 45 },
    { text: '品质好', type: 1, count: 32 }
  ]
  let product: Product = {
    id: id,
    name: name,
    modelCode: modelCode,
    brand: brand,
    category: category,
    imageUrl: '',
    specs: specs,
    aggregateScore: aggregateScore,
    aggregateRating: aggregateRating,
    totalReviewCount: totalReviewCount,
    platformListings: platforms,
    platformCount: platforms.length,
    lowestPrice: lowestPrice,
    priceSpread: priceSpread,
    historicalLow: historicalLow,
    priceHistory: priceHistory,
    reviewTags: reviewTags,
    publishDate: '2026-06-01',
    description: description
  }
  return product
}

let CATEGORIES: Category[] = [
  { id: 'cat1', name: '手机数码', icon: '📱', subCategories: [{ id: 'sub1', name: '智能手机' }, { id: 'sub2', name: '平板电脑' }] },
  { id: 'cat2', name: '电脑办公', icon: '💻', subCategories: [{ id: 'sub3', name: '笔记本' }, { id: 'sub4', name: '台式机' }] },
  { id: 'cat3', name: '家用电器', icon: '🏠', subCategories: [{ id: 'sub5', name: '空调' }, { id: 'sub6', name: '冰箱' }] },
  { id: 'cat4', name: '美妆个护', icon: '💄', subCategories: [{ id: 'sub7', name: '护肤' }, { id: 'sub8', name: '彩妆' }] },
  { id: 'cat5', name: '服饰鞋包', icon: '👗', subCategories: [{ id: 'sub9', name: '男装' }, { id: 'sub10', name: '女装' }] },
  { id: 'cat6', name: '食品生鲜', icon: '🍎', subCategories: [{ id: 'sub11', name: '水果' }, { id: 'sub12', name: '零食' }] }
]

let ALL_PRODUCTS: Product[] = [
  createProduct('p1', 'iPhone 16 Pro Max', 'MYW93CH/A', 'Apple', '手机数码', 8999, 9.2, 4.8, 15680, 500, 8499, '苹果最新旗舰手机'),
  createProduct('p2', '华为 Mate 70 Pro', 'ALN-AL80', '华为', '手机数码', 6999, 8.8, 4.7, 23400, 300, 6599, '华为旗舰手机'),
  createProduct('p3', 'MacBook Pro 14', 'MRX33CH/A', 'Apple', '电脑办公', 14999, 9.1, 4.7, 8900, 1000, 13999, '苹果专业笔记本'),
  createProduct('p4', 'ThinkPad X1 Carbon', '21HM0001CD', '联想', '电脑办公', 9999, 8.5, 4.5, 5600, 800, 9199, '商务旗舰笔记本'),
  createProduct('p5', '戴森 V15 吸尘器', 'SV48', '戴森', '家用电器', 4990, 8.6, 4.6, 12300, 400, 4590, '无绳吸尘器旗舰款'),
  createProduct('p6', '美的空调 1.5匹', 'KFR-35GW', '美的', '家用电器', 2999, 8.3, 4.4, 45600, 200, 2799, '变频冷暖空调'),
  createProduct('p7', '兰蔻小黑瓶', 'LAN001', '兰蔻', '美妆个护', 1080, 8.9, 4.7, 67800, 200, 880, '经典肌底精华液'),
  createProduct('p8', 'Nike Air Force 1', 'AF1-001', 'Nike', '服饰鞋包', 799, 8.4, 4.6, 23400, 150, 649, '经典空军一号板鞋'),
  createProduct('p9', 'AirPods Pro 3', 'MTV83CH/A', 'Apple', '手机数码', 1899, 9.0, 4.7, 34500, 200, 1699, '主动降噪耳机'),
  createProduct('p10', '戴尔 U2723QE', 'U2723QE', '戴尔', '电脑办公', 3499, 8.7, 4.6, 7800, 500, 2999, '4K专业显示器'),
  createProduct('p11', '小米 15 Pro', '23116PN5CC', '小米', '手机数码', 4999, 8.6, 4.6, 18900, 300, 4699, '小米影像旗舰手机'),
  createProduct('p12', '三星 Galaxy S25 Ultra', 'SM-S938B', '三星', '手机数码', 8499, 8.7, 4.5, 9800, 400, 7999, '三星安卓机皇'),
  createProduct('p13', '华为 MateBook X Pro', 'MRG-AL00', '华为', '电脑办公', 10999, 8.8, 4.6, 6700, 600, 9999, '华为轻薄商务本'),
  createProduct('p14', '小米 Redmi G Pro 显示器', 'REDMIG27Q', '小米', '电脑办公', 1299, 8.2, 4.4, 12300, 200, 1099, '2K高刷电竞显示器'),
  createProduct('p15', '格力空调 1.5匹', 'KFR-35GW', '格力', '家用电器', 3199, 8.5, 4.5, 38900, 300, 2999, '格力变频冷暖空调'),
  createProduct('p16', '海尔冰箱 501L', 'BCD-501WDPR', '海尔', '家用电器', 3299, 8.4, 4.4, 25600, 400, 3099, '海尔风冷无霜冰箱'),
  createProduct('p17', '飞利浦剃须刀', 'S5079', '飞利浦', '家用电器', 599, 8.3, 4.5, 34500, 100, 499, '飞利浦电动剃须刀'),
  createProduct('p18', '雅诗兰黛小棕瓶', 'EST001', '雅诗兰黛', '美妆个护', 1280, 9.0, 4.7, 56000, 200, 1080, '雅诗兰黛修护精华'),
  createProduct('p19', 'SK-II 神仙水', 'SKII001', 'SK-II', '美妆个护', 1590, 9.1, 4.8, 43000, 300, 1390, 'SK-II护肤精华露'),
  createProduct('p20', '欧莱雅紫熨斗', 'LOR001', '欧莱雅', '美妆个护', 399, 8.5, 4.5, 78000, 100, 329, '欧莱雅抗老精华'),
  createProduct('p21', '丝芙兰保湿面膜', 'SEPH001', '丝芙兰', '美妆个护', 149, 8.0, 4.3, 23000, 50, 99, '丝芙兰补水面膜'),
  createProduct('p22', 'Adidas Ultraboost', 'UB22-001', 'Adidas', '服饰鞋包', 1299, 8.6, 4.6, 18900, 200, 1099, '阿迪达斯跑鞋旗舰'),
  createProduct('p23', "Levi's 501 牛仔裤", '501-001', "Levi's", '服饰鞋包', 599, 8.4, 4.5, 27800, 150, 449, '李维斯经典直筒牛仔'),
  createProduct('p24', 'Zara 风衣外套', 'ZA-CT001', 'Zara', '服饰鞋包', 699, 8.0, 4.2, 15600, 200, 499, 'Zara春秋风衣'),
  createProduct('p25', 'Coach 男士钱包', 'COA-WL001', 'Coach', '服饰鞋包', 899, 8.5, 4.4, 9800, 200, 699, 'Coach真皮短款钱包'),
  createProduct('p26', '三只松鼠坚果礼盒', 'SZS-NUT01', '三只松鼠', '食品生鲜', 168, 8.4, 4.6, 56000, 50, 128, '三只松鼠每日坚果'),
  createProduct('p27', '茅台飞天 53度', 'MOUTAI-53', '茅台', '食品生鲜', 2999, 9.3, 4.9, 12000, 500, 2799, '贵州茅台酱香白酒'),
  createProduct('p28', '农夫山泉天然水', 'NFC-550', '农夫山泉', '食品生鲜', 12, 8.2, 4.5, 234000, 2, 10, '农夫山泉饮用天然水'),
  createProduct('p29', '良品铺子肉松饼', 'LPP-MSB01', '良品铺子', '食品生鲜', 39, 8.3, 4.5, 89000, 10, 29, '良品铺子肉松饼礼盒'),
  createProduct('p30', '百草味牛肉干', 'BCW-BJG01', '百草味', '食品生鲜', 49, 8.2, 4.4, 67000, 10, 39, '百草味五香牛肉干')
]

let HOT_RECOMMENDATIONS: Product[] = [
  ALL_PRODUCTS[0],
  ALL_PRODUCTS[1],
  ALL_PRODUCTS[2],
  ALL_PRODUCTS[4],
  ALL_PRODUCTS[7],
  ALL_PRODUCTS[8]
]

export class MockData {
  static getCategories(): Category[] {
    return CATEGORIES
  }

  static getProducts(): Product[] {
    return ALL_PRODUCTS
  }

  static getProductById(id: string): Product | undefined {
    let i: number = 0
    while (i < ALL_PRODUCTS.length) {
      if (ALL_PRODUCTS[i].id === id) {
        return ALL_PRODUCTS[i]
      }
      i = i + 1
    }
    return undefined
  }

  static getHotRecommendations(): Product[] {
    return HOT_RECOMMENDATIONS
  }

  static getProductCount(): number {
    return ALL_PRODUCTS.length
  }

  static getFilterGroups(categoryId: string): FilterGroup[] {
    if (categoryId === 'cat1') {
      return [
        {
          name: '品牌',
          type: 'brand',
          options: [
            { id: 'brand_apple', label: 'Apple', selected: false },
            { id: 'brand_huawei', label: '华为', selected: false },
            { id: 'brand_xiaomi', label: '小米', selected: false },
            { id: 'brand_oppo', label: 'OPPO', selected: false },
            { id: 'brand_vivo', label: 'vivo', selected: false },
            { id: 'brand_samsung', label: '三星', selected: false }
          ]
        },
        {
          name: '价格区间',
          type: 'price',
          options: [
            { id: 'price_0_2000', label: '0-2000', selected: false },
            { id: 'price_2000_4000', label: '2000-4000', selected: false },
            { id: 'price_4000_6000', label: '4000-6000', selected: false },
            { id: 'price_6000_above', label: '6000以上', selected: false }
          ]
        },
        {
          name: '特色功能',
          type: 'feature',
          options: [
            { id: 'feat_5g', label: '5G', selected: false },
            { id: 'feat_fold', label: '折叠屏', selected: false },
            { id: 'feat_camera', label: '拍照旗舰', selected: false },
            { id: 'feat_game', label: '游戏手机', selected: false },
            { id: 'feat_battery', label: '长续航', selected: false }
          ]
        }
      ]
    }
    if (categoryId === 'cat2') {
      return [
        {
          name: '品牌',
          type: 'brand',
          options: [
            { id: 'brand_apple', label: 'Apple', selected: false },
            { id: 'brand_lenovo', label: '联想', selected: false },
            { id: 'brand_dell', label: '戴尔', selected: false },
            { id: 'brand_huawei', label: '华为', selected: false }
          ]
        },
        {
          name: '价格区间',
          type: 'price',
          options: [
            { id: 'price_0_5000', label: '0-5000', selected: false },
            { id: 'price_5000_8000', label: '5000-8000', selected: false },
            { id: 'price_8000_12000', label: '8000-12000', selected: false },
            { id: 'price_12000_above', label: '12000以上', selected: false }
          ]
        }
      ]
    }
    return [
      {
        name: '品牌',
        type: 'brand',
        options: [
          { id: 'brand_popular', label: '热门品牌', selected: false }
        ]
      },
      {
        name: '价格区间',
        type: 'price',
        options: [
          { id: 'price_0_1000', label: '0-1000', selected: false },
          { id: 'price_1000_3000', label: '1000-3000', selected: false },
          { id: 'price_3000_above', label: '3000以上', selected: false }
        ]
      }
    ]
  }

  static getHotSearchKeywords(): string[] {
    return ['华为', 'iPhone', 'AirPods', '空调', '精华', 'Nike']
  }
}
