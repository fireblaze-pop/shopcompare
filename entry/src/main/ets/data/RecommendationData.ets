import { RatingRecord, ProductMeta } from '../models/RecommendationModels'

let PRODUCT_METAS: ProductMeta[] = [
  { asin: 'p1', title: 'iPhone 16 Pro Max', brand: 'Apple', category: '手机数码', price: 8999,
    feature: ['5G', 'A18芯片', '钛金属'], alsoBuy: ['p9', 'p3'], alsoView: ['p2', 'p11', 'p12'], description: '苹果最新旗舰手机' },
  { asin: 'p2', title: '华为 Mate 70 Pro', brand: '华为', category: '手机数码', price: 6999,
    feature: ['5G', '麒麟芯片', '卫星通信'], alsoBuy: ['p13', 'p9'], alsoView: ['p1', 'p11', 'p12'], description: '华为旗舰手机' },
  { asin: 'p3', title: 'MacBook Pro 14', brand: 'Apple', category: '电脑办公', price: 14999,
    feature: ['M3芯片', 'Liquid视网膜', '长续航'], alsoBuy: ['p10', 'p1'], alsoView: ['p4', 'p13', 'p14'], description: '苹果专业笔记本' },
  { asin: 'p4', title: 'ThinkPad X1 Carbon', brand: '联想', category: '电脑办公', price: 9999,
    feature: ['碳纤维', '轻薄', '商务'], alsoBuy: ['p10'], alsoView: ['p3', 'p13', 'p14'], description: '商务旗舰笔记本' },
  { asin: 'p5', title: '戴森 V15 吸尘器', brand: '戴森', category: '家用电器', price: 4990,
    feature: ['无绳', '激光探测', '强力吸尘'], alsoBuy: ['p6'], alsoView: ['p15', 'p16', 'p17'], description: '无绳吸尘器旗舰款' },
  { asin: 'p6', title: '美的空调 1.5匹', brand: '美的', category: '家用电器', price: 2999,
    feature: ['变频', '冷暖', '节能'], alsoBuy: ['p15'], alsoView: ['p5', 'p16', 'p17'], description: '变频冷暖空调' },
  { asin: 'p7', title: '兰蔻小黑瓶', brand: '兰蔻', category: '美妆个护', price: 1080,
    feature: ['精华', '修护', '抗老'], alsoBuy: ['p18', 'p19'], alsoView: ['p20', 'p21'], description: '经典肌底精华液' },
  { asin: 'p8', title: 'Nike Air Force 1', brand: 'Nike', category: '服饰鞋包', price: 799,
    feature: ['板鞋', '经典', '百搭'], alsoBuy: ['p22'], alsoView: ['p23', 'p24', 'p25'], description: '经典空军一号板鞋' },
  { asin: 'p9', title: 'AirPods Pro 3', brand: 'Apple', category: '手机数码', price: 1899,
    feature: ['主动降噪', '空间音频', '无线'], alsoBuy: ['p1', 'p3'], alsoView: ['p2', 'p11'], description: '主动降噪耳机' },
  { asin: 'p10', title: '戴尔 U2723QE', brand: '戴尔', category: '电脑办公', price: 3499,
    feature: ['4K', 'USB-C', '专业色准'], alsoBuy: ['p3', 'p4'], alsoView: ['p13', 'p14'], description: '4K专业显示器' },
  { asin: 'p11', title: '小米 15 Pro', brand: '小米', category: '手机数码', price: 4999,
    feature: ['5G', '徕卡影像', '快充'], alsoBuy: ['p9', 'p14'], alsoView: ['p1', 'p2', 'p12'], description: '小米影像旗舰手机' },
  { asin: 'p12', title: '三星 Galaxy S25 Ultra', brand: '三星', category: '手机数码', price: 8499,
    feature: ['5G', 'S Pen', '折叠屏'], alsoBuy: ['p9'], alsoView: ['p1', 'p2', 'p11'], description: '三星安卓机皇' },
  { asin: 'p13', title: '华为 MateBook X Pro', brand: '华为', category: '电脑办公', price: 10999,
    feature: ['轻薄', '触控屏', '鸿蒙'], alsoBuy: ['p2', 'p10'], alsoView: ['p3', 'p4', 'p14'], description: '华为轻薄商务本' },
  { asin: 'p14', title: '小米 Redmi G Pro 显示器', brand: '小米', category: '电脑办公', price: 1299,
    feature: ['2K', '高刷', '电竞'], alsoBuy: ['p11'], alsoView: ['p3', 'p4', 'p10'], description: '2K高刷电竞显示器' },
  { asin: 'p15', title: '格力空调 1.5匹', brand: '格力', category: '家用电器', price: 3199,
    feature: ['变频', '冷暖', '静音'], alsoBuy: ['p6'], alsoView: ['p5', 'p16', 'p17'], description: '格力变频冷暖空调' },
  { asin: 'p16', title: '海尔冰箱 501L', brand: '海尔', category: '家用电器', price: 3299,
    feature: ['风冷', '无霜', '大容量'], alsoBuy: ['p6'], alsoView: ['p5', 'p15', 'p17'], description: '海尔风冷无霜冰箱' },
  { asin: 'p17', title: '飞利浦剃须刀', brand: '飞利浦', category: '家用电器', price: 599,
    feature: ['电动', '防水', '干湿双剃'], alsoBuy: ['p5'], alsoView: ['p6', 'p15', 'p16'], description: '飞利浦电动剃须刀' },
  { asin: 'p18', title: '雅诗兰黛小棕瓶', brand: '雅诗兰黛', category: '美妆个护', price: 1280,
    feature: ['精华', '抗老', '修护'], alsoBuy: ['p7', 'p19'], alsoView: ['p20', 'p21'], description: '雅诗兰黛修护精华' },
  { asin: 'p19', title: 'SK-II 神仙水', brand: 'SK-II', category: '美妆个护', price: 1590,
    feature: ['精华', 'PITERA', '提亮'], alsoBuy: ['p7', 'p18'], alsoView: ['p20', 'p21'], description: 'SK-II护肤精华露' },
  { asin: 'p20', title: '欧莱雅紫熨斗', brand: '欧莱雅', category: '美妆个护', price: 399,
    feature: ['精华', '抗老', '平价'], alsoBuy: ['p7'], alsoView: ['p18', 'p19', 'p21'], description: '欧莱雅抗老精华' },
  { asin: 'p21', title: '丝芙兰保湿面膜', brand: '丝芙兰', category: '美妆个护', price: 149,
    feature: ['面膜', '补水', '平价'], alsoBuy: ['p7', 'p20'], alsoView: ['p18', 'p19'], description: '丝芙兰补水面膜' },
  { asin: 'p22', title: 'Adidas Ultraboost', brand: 'Adidas', category: '服饰鞋包', price: 1299,
    feature: ['跑鞋', 'Boost', '缓震'], alsoBuy: ['p8'], alsoView: ['p23', 'p24', 'p25'], description: '阿迪达斯跑鞋旗舰' },
  { asin: 'p23', title: "Levi's 501 牛仔裤", brand: "Levi's", category: '服饰鞋包', price: 599,
    feature: ['牛仔', '直筒', '经典'], alsoBuy: ['p8', 'p22'], alsoView: ['p24', 'p25'], description: '李维斯经典直筒牛仔' },
  { asin: 'p24', title: 'Zara 风衣外套', brand: 'Zara', category: '服饰鞋包', price: 699,
    feature: ['风衣', '春秋', '简约'], alsoBuy: ['p8'], alsoView: ['p22', 'p23', 'p25'], description: 'Zara春秋风衣' },
  { asin: 'p25', title: 'Coach 男士钱包', brand: 'Coach', category: '服饰鞋包', price: 899,
    feature: ['真皮', '短款', '礼品'], alsoBuy: ['p8'], alsoView: ['p22', 'p23', 'p24'], description: 'Coach真皮短款钱包' },
  { asin: 'p26', title: '三只松鼠坚果礼盒', brand: '三只松鼠', category: '食品生鲜', price: 168,
    feature: ['坚果', '礼盒', '零食'], alsoBuy: ['p29', 'p30'], alsoView: ['p27', 'p28'], description: '三只松鼠每日坚果' },
  { asin: 'p27', title: '茅台飞天 53度', brand: '茅台', category: '食品生鲜', price: 2999,
    feature: ['白酒', '酱香', '礼品'], alsoBuy: ['p26'], alsoView: ['p28', 'p29', 'p30'], description: '贵州茅台酱香白酒' },
  { asin: 'p28', title: '农夫山泉天然水', brand: '农夫山泉', category: '食品生鲜', price: 12,
    feature: ['饮用水', '天然', '日常'], alsoBuy: ['p26', 'p29'], alsoView: ['p27', 'p30'], description: '农夫山泉饮用天然水' },
  { asin: 'p29', title: '良品铺子肉松饼', brand: '良品铺子', category: '食品生鲜', price: 39,
    feature: ['零食', '肉松', '礼盒'], alsoBuy: ['p26', 'p30'], alsoView: ['p27', 'p28'], description: '良品铺子肉松饼礼盒' },
  { asin: 'p30', title: '百草味牛肉干', brand: '百草味', category: '食品生鲜', price: 49,
    feature: ['牛肉干', '零食', '五香'], alsoBuy: ['p26', 'p29'], alsoView: ['p27', 'p28'], description: '百草味五香牛肉干' }
]

interface UserTaste {
  userId: string
  preferredCategory: string
  preferredBrand: string
}

let USER_TASTES: UserTaste[] = [
  { userId: 'u1', preferredCategory: '手机数码', preferredBrand: 'Apple' },
  { userId: 'u2', preferredCategory: '手机数码', preferredBrand: '华为' },
  { userId: 'u3', preferredCategory: '手机数码', preferredBrand: '小米' },
  { userId: 'u4', preferredCategory: '手机数码', preferredBrand: '三星' },
  { userId: 'u5', preferredCategory: '电脑办公', preferredBrand: 'Apple' },
  { userId: 'u6', preferredCategory: '电脑办公', preferredBrand: '联想' },
  { userId: 'u7', preferredCategory: '电脑办公', preferredBrand: '华为' },
  { userId: 'u8', preferredCategory: '家用电器', preferredBrand: '戴森' },
  { userId: 'u9', preferredCategory: '家用电器', preferredBrand: '美的' },
  { userId: 'u10', preferredCategory: '家用电器', preferredBrand: '格力' },
  { userId: 'u11', preferredCategory: '美妆个护', preferredBrand: '兰蔻' },
  { userId: 'u12', preferredCategory: '美妆个护', preferredBrand: '雅诗兰黛' },
  { userId: 'u13', preferredCategory: '美妆个护', preferredBrand: 'SK-II' },
  { userId: 'u14', preferredCategory: '服饰鞋包', preferredBrand: 'Nike' },
  { userId: 'u15', preferredCategory: '服饰鞋包', preferredBrand: 'Adidas' },
  { userId: 'u16', preferredCategory: '服饰鞋包', preferredBrand: "Levi's" },
  { userId: 'u17', preferredCategory: '食品生鲜', preferredBrand: '三只松鼠' },
  { userId: 'u18', preferredCategory: '食品生鲜', preferredBrand: '茅台' },
  { userId: 'u19', preferredCategory: '食品生鲜', preferredBrand: '良品铺子' },
  { userId: 'u20', preferredCategory: '食品生鲜', preferredBrand: '百草味' }
]

function isRelatedCategory(catA: string, catB: string): boolean {
  if (catA === '手机数码' && catB === '电脑办公') {
    return true
  }
  if (catA === '电脑办公' && catB === '手机数码') {
    return true
  }
  if (catA === '家用电器' && catB === '食品生鲜') {
    return true
  }
  if (catA === '食品生鲜' && catB === '家用电器') {
    return true
  }
  if (catA === '美妆个护' && catB === '服饰鞋包') {
    return true
  }
  if (catA === '服饰鞋包' && catB === '美妆个护') {
    return true
  }
  return false
}

function buildRatings(): RatingRecord[] {
  let ratings: RatingRecord[] = []
  let baseTime: number = 1700000000
  let i: number = 0
  while (i < USER_TASTES.length) {
    let taste: UserTaste = USER_TASTES[i]
    let flagshipScore: number = 4 + (i % 2)
    let r1: RatingRecord = {
      reviewerId: taste.userId, asin: 'p1', overall: flagshipScore,
      timestamp: baseTime + i, helpfulVotes: (i * 3) % 20
    }
    ratings.push(r1)
    let r2: RatingRecord = {
      reviewerId: taste.userId, asin: 'p27', overall: 4 + ((i + 1) % 2),
      timestamp: baseTime + i + 1, helpfulVotes: (i * 2) % 15
    }
    ratings.push(r2)
    let j: number = 0
    while (j < PRODUCT_METAS.length) {
      let meta: ProductMeta = PRODUCT_METAS[j]
      if (meta.asin === 'p1' || meta.asin === 'p27') {
        j = j + 1
        continue
      }
      let inPrefCat: boolean = meta.category === taste.preferredCategory
      let inPrefBrand: boolean = meta.brand === taste.preferredBrand
      let related: boolean = isRelatedCategory(meta.category, taste.preferredCategory)
      let rate: boolean = false
      let score: number = 3
      if (inPrefCat) {
        rate = true
        score = 5
      } else if (inPrefBrand) {
        rate = true
        score = 5
      } else if (related && (i + j) % 2 === 0) {
        rate = true
        score = 4
      } else if ((i + j) % 5 === 0) {
        rate = true
        score = 3
      }
      if (rate) {
        let rec: RatingRecord = {
          reviewerId: taste.userId, asin: meta.asin, overall: score,
          timestamp: baseTime + i * 100 + j, helpfulVotes: (i + j) % 12
        }
        ratings.push(rec)
      }
      j = j + 1
    }
    i = i + 1
  }
  return ratings
}

let SAMPLE_RATINGS: RatingRecord[] = buildRatings()

let SAMPLE_USERS: string[] = [
  'u1', 'u2', 'u3', 'u4', 'u5', 'u6', 'u7', 'u8', 'u9', 'u10',
  'u11', 'u12', 'u13', 'u14', 'u15', 'u16', 'u17', 'u18', 'u19', 'u20'
]

let CURRENT_USER_ID: string = 'u_me'

export class RecommendationData {
  static getProductMetas(): ProductMeta[] {
    return PRODUCT_METAS
  }

  static getSampleRatings(): RatingRecord[] {
    return SAMPLE_RATINGS
  }

  static getSampleUsers(): string[] {
    return SAMPLE_USERS
  }

  static getCurrentUserId(): string {
    return CURRENT_USER_ID
  }

  static getRatingCount(): number {
    return SAMPLE_RATINGS.length
  }
}
