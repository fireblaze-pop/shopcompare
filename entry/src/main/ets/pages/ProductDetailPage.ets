import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { Product, PlatformListing, PricePoint, ReviewTag } from '../models/DataModels';
import { MockData } from '../data/MockData';
import { PreferenceManager } from '../utils/PreferenceManager';
import { NavParams } from '../utils/PreferenceManager';
import { RadarDimension, RecommendationItem, ProductMeta } from '../models/RecommendationModels';
import { DataProvider } from '../data/DataProvider';
import { ProductDimensionScorer } from '../utils/ProductDimensionScorer';
import { RecommendationEngine } from '../utils/RecommendationEngine';
import { BehaviorManager } from '../utils/BehaviorManager';
import { RadarChart } from '../components/RadarChart';
import { RecommendationSection } from '../components/RecommendationSection';
import { formatPrice, formatPriceBrief } from '../utils/FormatUtils';

interface DetailPageParams {
  productId: string;
}

@Entry
@Component
struct ProductDetailPage {
  @State product: Product | undefined = undefined;
  @State isLoading: boolean = true;
  @State currentImageIndex: number = 0;
  @State isFavorited: boolean = false;
  @State priceSortAsc: boolean = true;
  @State sortedListings: PlatformListing[] = [];
  @State positiveTags: ReviewTag[] = [];
  @State negativeTags: ReviewTag[] = [];
  @State radarDimensions: RadarDimension[] = [];
  @State similarProducts: RecommendationItem[] = [];

  aboutToAppear(): void {
    let productId: string = NavParams.productId;
    this.loadProductData(productId);
  }

  loadProductData(productId: string): void {
    this.isLoading = true;
    setTimeout(() => {
      let allProducts: Product[] = MockData.getProducts();
      let i: number = 0;
      while (i < allProducts.length) {
        if (allProducts[i].id === productId) {
          this.product = allProducts[i];
          break;
        }
        i = i + 1;
      }
      if (this.product !== undefined) {
        this.sortPlatformListings(true);
        this.isFavorited = PreferenceManager.isFavorite(productId);
        this.computeReviewTags();
        this.computeRadarDimensions();
        this.loadSimilarProducts(productId);
        BehaviorManager.getInstance().recordView(productId);
      }
      this.isLoading = false;
    }, 500);
  }

  computeRadarDimensions(): void {
    if (this.product === undefined) {
      return;
    }
    let repo = DataProvider.getProductRepository();
    let ds = DataProvider.getRecommendationDataSource();
    let metas: ProductMeta[] = ds.getProductMetas();
    let meta: ProductMeta | undefined = undefined;
    let i: number = 0;
    while (i < metas.length) {
      if (metas[i].asin === this.product!.id) {
        meta = metas[i];
        break;
      }
      i = i + 1;
    }
    this.radarDimensions = ProductDimensionScorer.score(this.product!, meta, repo);
  }

  loadSimilarProducts(productId: string): void {
    let engine = RecommendationEngine.getInstance();
    this.similarProducts = engine.getSimilarProducts(productId, 6);
  }

  sortPlatformListings(asc: boolean): void {
    if (this.product === undefined) {
      return;
    }
    let listings: PlatformListing[] = [];
    let i: number = 0;
    while (i < this.product!.platformListings.length) {
      listings.push(this.product!.platformListings[i]);
      i = i + 1;
    }
    if (asc) {
      listings.sort((a: PlatformListing, b: PlatformListing): number => {
        return a.price - b.price;
      });
    } else {
      listings.sort((a: PlatformListing, b: PlatformListing): number => {
        return b.price - a.price;
      });
    }
    this.sortedListings = listings;
  }

  toggleFavorite(): void {
    if (this.product === undefined) {
      return;
    }
    this.isFavorited = !this.isFavorited;
    if (this.isFavorited) {
      PreferenceManager.addFavorite(this.product!.id);
      BehaviorManager.getInstance().recordFavorite(this.product!.id);
      promptAction.showToast({ message: '已加入收藏' });
    } else {
      PreferenceManager.removeFavorite(this.product!.id);
      promptAction.showToast({ message: '已取消收藏' });
    }
  }

  computeReviewTags(): void {
    if (this.product === undefined) {
      return;
    }
    let ptags: ReviewTag[] = [];
    let ntags: ReviewTag[] = [];
    let i: number = 0;
    while (i < this.product!.reviewTags.length) {
      if (this.product!.reviewTags[i].type === 0) {
        ptags.push(this.product!.reviewTags[i]);
      } else {
        ntags.push(this.product!.reviewTags[i]);
      }
      i = i + 1;
    }
    this.positiveTags = ptags;
    this.negativeTags = ntags;
  }

  getHighestPrice(): number {
    if (this.product === undefined) {
      return 0;
    }
    let highest: number = this.product!.platformListings[0].price;
    let i: number = 1;
    while (i < this.product!.platformListings.length) {
      if (this.product!.platformListings[i].price > highest) {
        highest = this.product!.platformListings[i].price;
      }
      i = i + 1;
    }
    return highest;
  }

  getCategoryEmoji(product: Product | undefined): string {
    if (product === undefined) {
      return '\uD83D\uDCE6';
    }
    let category: string = product.category;
    if (category === '手机数码') {
      return '\uD83D\uDCF1';
    }
    if (category === '电脑办公') {
      return '\uD83D\uDCBB';
    }
    if (category === '家用电器') {
      return '\uD83C\uDFE0';
    }
    if (category === '美妆个护') {
      return '\uD83D\uDC84';
    }
    if (category === '服饰鞋包') {
      return '\uD83D\uDC57';
    }
    return '\uD83D\uDCE6';
  }

  getStarDisplayChars(rating: number): string[] {
    let chars: string[] = [];
    let s: number = 0;
    while (s < 5) {
      if (s < Math.floor(rating)) {
        chars.push('\u2605');
      } else {
        chars.push('\u2606');
      }
      s = s + 1;
    }
    return chars;
  }

  @Builder
  buildImageCarousel(): void {
    Column() {
      Column() {
        if (this.product !== undefined && this.product!.imageUrl.length > 0) {
          Image(this.product!.imageUrl)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
        }
        if (this.product === undefined || this.product!.imageUrl.length === 0) {
          Text(this.getCategoryEmoji(this.product))
            .fontSize(64)
        }
      }
      .width('100%')
      .height(200)
      .backgroundColor('#E8E8ED')
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Row() {
        Text('\u25CF')
          .fontSize(8)
          .fontColor('#007AFF')
          .margin({ left: 4, right: 4 })
        Text('\u25CB')
          .fontSize(8)
          .fontColor('#C7C7CC')
          .margin({ left: 4, right: 4 })
        Text('\u25CB')
          .fontSize(8)
          .fontColor('#C7C7CC')
          .margin({ left: 4, right: 4 })
      }
      .margin({ top: 10 })
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(240)
    .padding({ left: 16, right: 16, top: 16, bottom: 0 })
  }

  @Builder
  buildBasicInfo(): void {
    Column() {
      Text(this.product!.name)
        .fontSize(22)
        .fontWeight(700)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Text(this.product!.brand)
          .fontSize(13)
          .fontColor('#8E8E93')
        Text(' \u00B7 ' + this.product!.modelCode)
          .fontSize(13)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .margin({ bottom: 6 })

      Text('发布日期: ' + this.product!.publishDate)
        .fontSize(13)
        .fontColor('#8E8E93')
        .width('100%')
        .margin({ bottom: 10 })

      Text(this.product!.description)
        .fontSize(14)
        .fontColor('#3C3C3C')
        .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16, top: 12 })
  }

  @Builder
  buildPriceSummary(): void {
    Column() {
      Text('跨平台比价')
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 14 })

      Row() {
        Column() {
          Text('价格区间')
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ bottom: 4 })
          Text(formatPrice(this.product!.lowestPrice) + ' - ' + formatPrice(this.getHighestPrice()))
            .fontSize(22)
            .fontWeight(700)
            .fontColor('#1C1C1E')

          Text(formatPrice(this.product!.lowestPrice))
            .fontSize(14)
            .fontColor('#FF3B30')
            .fontWeight(600)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Text('跨平台价差')
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ bottom: 4 })
          Text(formatPrice(this.product!.priceSpread))
            .fontSize(20)
            .fontWeight(600)
            .fontColor('#FF3B30')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#FFEEEE')
            .borderRadius(8)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')

      Row() {
        Text('历史最低: ' + formatPrice(this.product!.historicalLow))
          .fontSize(13)
          .fontColor('#34C759')
          .fontWeight(500)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#E8F8ED')
          .borderRadius(6)
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16, top: 12 })
  }

  @Builder
  buildPlatformPriceList(): void {
    Column() {
      Row() {
        Text('各平台价格')
          .fontSize(18)
          .fontWeight(600)
          .fontColor('#1C1C1E')

        Blank()

        Text('按价格排序')
          .fontSize(13)
          .fontColor('#007AFF')
          .onClick(() => {
            this.priceSortAsc = !this.priceSortAsc;
            this.sortPlatformListings(this.priceSortAsc);
          })
      }
      .width('100%')
      .margin({ bottom: 14 })

      ForEach(this.sortedListings, (listing: PlatformListing, index: number) => {
        this.buildPlatformPriceItem(listing)
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16, top: 12 })
  }

  isListingLowest(listing: PlatformListing): boolean {
    if (this.product === undefined) {
      return false;
    }
    return listing.price === this.product!.lowestPrice;
  }

  @Builder
  buildPlatformPriceItem(listing: PlatformListing): void {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(listing.platform)
              .fontSize(15)
              .fontWeight(500)
              .fontColor('#1C1C1E')

            if (this.isListingLowest(listing)) {
              Text('最低价')
                .fontSize(10)
                .fontColor('#FFFFFF')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#FF3B30')
                .borderRadius(8)
                .margin({ left: 8 })
            }
          }

          Row() {
            Text(listing.rating.toFixed(1))
              .fontSize(12)
              .fontColor('#FF9500')
            Text(' ' + listing.reviewCount.toString() + '条评价')
              .fontSize(12)
              .fontColor('#8E8E93')
              .margin({ left: 4 })
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(formatPrice(listing.price))
            .fontSize(18)
            .fontWeight(700)
            .fontColor(this.isListingLowest(listing) ? '#FF3B30' : '#1C1C1E')

          if (listing.inStock) {
            Text('有货')
              .fontSize(11)
              .fontColor('#34C759')
              .margin({ top: 2 })
          } else {
            Text('缺货')
              .fontSize(11)
              .fontColor('#8E8E93')
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Divider()
        .width('100%')
        .height(0.5)
        .color('#E5E5EA')
    }
    .width('100%')
  }

  @Builder
  buildPriceHistoryChart(): void {
    Column() {
      Text('价格走势（近30天）')
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 14 })

      Row() {
        if (this.product!.priceHistory.length === 0) {
          Text('暂无价格数据')
            .fontSize(14)
            .fontColor('#8E8E93')
        } else {
          ForEach(this.product!.priceHistory, (point: PricePoint, pidx: number) => {
            Column() {
              Text(formatPriceBrief(point.price))
                .fontSize(9)
                .fontColor('#8E8E93')
                .margin({ bottom: 4 })
              Column()
                .width(20)
                .height(60 + pidx * 10)
                .backgroundColor(pidx === 2 ? '#FF3B30' : '#007AFF')
                .borderRadius(3)
              Text(point.date.substring(5))
                .fontSize(8)
                .fontColor('#C7C7CC')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 6 })
          })
        }
      }
      .width('100%')
      .height(140)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Bottom)
      .padding({ top: 10 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16, top: 12 })
  }

  @Builder
  buildRatingsSection(): void {
    Column() {
      Row() {
        Column() {
          Text(this.product!.aggregateScore.toString())
            .fontSize(60)
            .fontWeight(700)
            .fontColor('#007AFF')
            .fontFamily('sans-serif-medium')

          Text(this.product!.aggregateRating.toFixed(1) + ' 分')
            .fontSize(14)
            .fontColor('#3C3C3C')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 24 })

        Column() {
          this.buildStarDisplay(this.product!.aggregateRating)

          Text('共 ' + this.product!.totalReviewCount.toString() + ' 条评价')
            .fontSize(13)
            .fontColor('#8E8E93')
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })

      Divider()
        .width('100%')
        .height(0.5)
        .color('#E5E5EA')
        .margin({ top: 4, bottom: 12 })

      Text('各平台评分')
        .fontSize(14)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 10 })

      ForEach(this.product!.platformListings, (listing: PlatformListing) => {
        Row() {
          Text(listing.platform)
            .fontSize(13)
            .fontColor('#3C3C3C')
            .width(60)

          Row() {
            ForEach(this.getStarDisplayChars(listing.rating), (ch: string) => {
              Text(ch)
                .fontSize(14)
                .fontColor(ch === '\u2605' ? '#FF9500' : '#C7C7CC')
            })
          }

          Blank()

          Text(listing.rating.toFixed(1))
            .fontSize(13)
            .fontColor('#3C3C3C')
            .fontWeight(500)
        }
        .width('100%')
        .padding({ top: 6, bottom: 6 })
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16, top: 12 })
  }

  @Builder
  buildStarDisplay(rating: number): void {
    Row() {
      ForEach(this.getStarDisplayChars(rating), (ch: string) => {
        Text(ch)
          .fontSize(20)
          .fontColor(ch === '\u2605' ? '#FF9500' : '#C7C7CC')
      })
    }
  }

  @Builder
  buildReviewTags(): void {
    Column() {
      Text('用户评价关键词')
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 14 })

      if (this.positiveTags.length > 0) {
        Text('好评关键词')
          .fontSize(13)
          .fontColor('#8E8E93')
          .width('100%')
          .margin({ bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.positiveTags, (tag: ReviewTag) => {
            this.buildTagChip(tag, 0)
          })
        }
        .width('100%')
        .margin({ bottom: 14 })
      }

      if (this.negativeTags.length > 0) {
        Text('差评关键词')
          .fontSize(13)
          .fontColor('#8E8E93')
          .width('100%')
          .margin({ bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.negativeTags, (tag: ReviewTag) => {
            this.buildTagChip(tag, 1)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16, top: 12 })
  }

  @Builder
  buildTagChip(tag: ReviewTag, tagType: number): void {
    Text(tag.text + ' ' + tag.count.toString())
      .fontSize(12)
      .fontColor(tagType === 0 ? '#007AFF' : '#FF3B30')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(tagType === 0 ? '#EBF5FF' : '#FFF0F0')
      .borderRadius(14)
      .margin({ right: 8, bottom: 8 })
  }

  @Builder
  buildRadarChart(): void {
    Column() {
      Text('商品画像')
        .fontSize(18)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 14 })

      Row() {
        Text('六维综合评价')
          .fontSize(13)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .margin({ bottom: 10 })

      if (this.radarDimensions.length >= 6) {
        Row() {
          RadarChart({ dimensions: this.radarDimensions, chartSize: 300 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ left: 16, right: 16, top: 12 })
  }

  @Builder
  buildSimilarProducts(): void {
    Column() {
      if (this.similarProducts.length > 0) {
        RecommendationSection({
          title: '相似商品推荐',
          items: this.similarProducts,
          onSeeMore: (): void => {
            router.back();
          }
        })
      }
    }
    .width('100%')
    .margin({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          Row() {
            Text('\u2190')
              .fontSize(24)
              .fontColor('#1C1C1E')
              .padding({ right: 12 })
              .onClick(() => {
                router.back();
              })
            Text('加载中...')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#1C1C1E')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('#FFFFFF')

          Column() {
            ForEach([0, 1, 2, 3], (item: number) => {
              Row()
                .width('100%')
                .height(120)
                .backgroundColor('#E5E5EA')
                .borderRadius(16)
                .margin({ left: 16, right: 16, top: 12 })
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F2F2F7')
          .padding({ top: 8 })
        }
        .width('100%')
        .height('100%')
      } else if (this.product === undefined) {
        Column() {
          Row() {
            Text('\u2190')
              .fontSize(24)
              .fontColor('#1C1C1E')
              .padding({ right: 12 })
              .onClick(() => {
                router.back();
              })
            Text('商品详情')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#1C1C1E')
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('#FFFFFF')

          Column() {
            Text('\uD83D\uDE22')
              .fontSize(64)
              .margin({ bottom: 16 })
            Text('商品未找到')
              .fontSize(16)
              .fontColor('#3C3C3C')
              .fontWeight(500)
            Button('返回')
              .fontSize(15)
              .fontColor('#007AFF')
              .backgroundColor('#FFFFFF')
              .borderRadius(20)
              .borderWidth(1)
              .borderColor('#007AFF')
              .margin({ top: 20 })
              .onClick(() => {
                router.back();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F2F2F7')
        }
        .width('100%')
        .height('100%')
      } else {
        Column() {
          Row() {
            Text('\u2190')
              .fontSize(24)
              .fontColor('#1C1C1E')
              .padding({ right: 12 })
              .onClick(() => {
                router.back();
              })
            Text('商品详情')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#1C1C1E')
              .layoutWeight(1)

            Text(this.isFavorited ? '\u2764' : '\u2661')
              .fontSize(22)
              .fontColor(this.isFavorited ? '#FF3B30' : '#8E8E93')
              .onClick(() => {
                this.toggleFavorite();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('#FFFFFF')

          Scroll() {
            Column() {
              this.buildImageCarousel()
              this.buildBasicInfo()
              this.buildRadarChart()
              this.buildPriceSummary()
              this.buildPlatformPriceList()
              this.buildPriceHistoryChart()
              this.buildRatingsSection()
              this.buildReviewTags()
              this.buildSimilarProducts()
            }
            .width('100%')
            .padding({ bottom: 80 })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F2F2F7')
          .scrollBar(BarState.Off)

          Row() {
            Button('查看商品')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#007AFF')
              .borderRadius(24)
              .layoutWeight(1)
              .height(48)
              .onClick(() => {
                promptAction.showToast({ message: '跳转至商品详情' });
              })

            Blank().width(12)

            Button(this.isFavorited ? '已收藏' : '加入收藏')
              .fontSize(16)
              .fontColor(this.isFavorited ? '#007AFF' : '#FFFFFF')
              .backgroundColor(this.isFavorited ? '#FFFFFF' : '#007AFF')
              .borderRadius(24)
              .borderWidth(this.isFavorited ? 1 : 0)
              .borderColor(this.isFavorited ? '#007AFF' : Color.Transparent)
              .layoutWeight(1)
              .height(48)
              .onClick(() => {
                this.toggleFavorite();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFF')
          .height(64)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F2F2F7')
      }
    }
    .width('100%')
    .height('100%')
  }
}
