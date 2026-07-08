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
            .height(220)
            .objectFit(ImageFit.Contain)
        }

        if (this.product === undefined || this.product!.imageUrl.length === 0) {
          Image($r('app.media.detail_product_placeholder'))
            .width(64)
            .height(64)
            .objectFit(ImageFit.Contain)
        }
      }
      .width('100%')
      .height(220)
      .backgroundColor('#F7F8FA')
      .borderRadius(18)
      .border({
        width: 1,
        color: '#ECEEF2'
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Row({ space: 6 }) {
        Column()
          .width(18)
          .height(5)
          .borderRadius(3)
          .backgroundColor('#5267E8')

        Column()
          .width(5)
          .height(5)
          .borderRadius(3)
          .backgroundColor('#D9DCE5')

        Column()
          .width(5)
          .height(5)
          .borderRadius(3)
          .backgroundColor('#D9DCE5')
      }
      .margin({ top: 12 })
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 16,
      bottom: 2
    })
  }

  @Builder
  buildBasicInfo(): void {
    Column() {
      Text(this.product!.name)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 12 })

      Row({ space: 8 }) {
        Text(this.product!.brand)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5267E8')
          .padding({
            left: 9,
            right: 9,
            top: 4,
            bottom: 4
          })
          .backgroundColor('#EEF1FF')
          .borderRadius(6)

        if (this.product!.modelCode.length > 0) {
          Text(this.product!.modelCode)
            .fontSize(12)
            .fontColor('#6F737B')
            .padding({
              left: 9,
              right: 9,
              top: 4,
              bottom: 4
            })
            .backgroundColor('#F5F6F8')
            .borderRadius(6)
        }
      }
      .width('100%')
      .margin({ bottom: 11 })

      Text(this.product!.publishDate + ' 发布')
        .fontSize(13)
        .fontColor('#8E8E93')
        .width('100%')
        .margin({ bottom: 12 })

      if (this.product!.description.length > 0) {
        Divider()
          .strokeWidth(0.5)
          .color('#ECEEF2')
          .margin({ bottom: 12 })

        Text(this.product!.description)
          .fontSize(14)
          .fontColor('#4C4F56')
          .lineHeight(22)
          .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .margin({
      left: 16,
      right: 16,
      top: 12
    })
  }

  @Builder
  buildPriceSummary(): void {
    Column() {
      this.buildSectionHeader(
        '跨平台比价',
        '快速查看最低价与平台价差'
      )

      Row({ space: 12 }) {
        Column({ space: 5 }) {
          Text('全网最低')
            .fontSize(12)
            .fontColor('#8E8E93')

          Text(formatPrice(this.product!.lowestPrice))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF3B30')

          Text(
            '区间 ' +
            formatPrice(this.product!.lowestPrice) +
            ' - ' +
            formatPrice(this.getHighestPrice())
          )
            .fontSize(11)
            .fontColor('#A0A3AA')
        }
        .layoutWeight(1)
        .height(98)
        .padding(14)
        .backgroundColor('#FFF7F6')
        .borderRadius(14)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 5 }) {
          Text('平台价差')
            .fontSize(12)
            .fontColor('#8E8E93')

          Text(formatPrice(this.product!.priceSpread))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#5267E8')

          Text('比价后再决定')
            .fontSize(11)
            .fontColor('#A0A3AA')
        }
        .layoutWeight(1)
        .height(98)
        .padding(14)
        .backgroundColor('#F5F6FF')
        .borderRadius(14)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row() {
        Text('历史最低')
          .fontSize(12)
          .fontColor('#2D8A4E')

        Text(formatPrice(this.product!.historicalLow))
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2D8A4E')
          .margin({ left: 6 })
      }
      .padding({
        left: 11,
        right: 11,
        top: 6,
        bottom: 6
      })
      .backgroundColor('#EEF9F1')
      .borderRadius(8)
      .margin({ top: 14 })
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .margin({
      left: 16,
      right: 16,
      top: 12
    })
  }

  @Builder
  buildPlatformPriceList(): void {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text('各平台价格')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text('按平台报价对比')
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text(this.priceSortAsc ? '价格升序' : '价格降序')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5267E8')
          .padding({
            left: 10,
            right: 10,
            top: 6,
            bottom: 6
          })
          .backgroundColor('#EEF1FF')
          .borderRadius(8)
          .onClick(() => {
            this.priceSortAsc = !this.priceSortAsc;
            this.sortPlatformListings(this.priceSortAsc);
          })
      }
      .width('100%')
      .margin({ bottom: 10 })

      ForEach(this.sortedListings, (listing: PlatformListing) => {
        this.buildPlatformPriceItem(listing)
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .margin({
      left: 16,
      right: 16,
      top: 12
    })
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
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')

            if (this.isListingLowest(listing)) {
              Text('最低价')
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FF3B30')
                .padding({
                  left: 7,
                  right: 7,
                  top: 3,
                  bottom: 3
                })
                .backgroundColor('#FFF1F0')
                .borderRadius(6)
                .margin({ left: 8 })
            }
          }

          Row() {
            Text(listing.rating.toFixed(1))
              .fontSize(12)
              .fontColor('#FF9500')

            Text(
              listing.reviewCount.toString() +
              ' 条评价'
            )
              .fontSize(12)
              .fontColor('#8E8E93')
              .margin({ left: 6 })
          }
          .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(formatPrice(listing.price))
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(
              this.isListingLowest(listing) ?
              '#FF3B30' :
              '#1C1C1E'
            )

          Text(listing.inStock ? '有货' : '缺货')
            .fontSize(11)
            .fontColor(
              listing.inStock ?
              '#2D8A4E' :
              '#8E8E93'
            )
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({
        top: 14,
        bottom: 14
      })

      Divider()
        .strokeWidth(0.5)
        .color('#ECEEF2')
    }
    .width('100%')
  }

  @Builder
  buildPriceHistoryChart(): void {
    Column() {
      this.buildSectionHeader(
        '价格走势',
        '近30天价格变化'
      )

      Row() {
        if (this.product!.priceHistory.length === 0) {
          Column({ space: 8 }) {
            Text('暂无价格数据')
              .fontSize(14)
              .fontColor('#8E8E93')

            Text('有新的价格记录后会显示在这里')
              .fontSize(12)
              .fontColor('#B0B3BA')
          }
          .width('100%')
          .height(130)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          ForEach(
            this.product!.priceHistory,
            (point: PricePoint, pidx: number) => {
              Column() {
                Text(formatPriceBrief(point.price))
                  .fontSize(10)
                  .fontColor('#7C7F87')
                  .margin({ bottom: 6 })

                Column()
                  .width(24)
                  .height(60 + pidx * 10)
                  .backgroundColor(
                    pidx === 2 ?
                    '#FF6B61' :
                    '#7A89F2'
                  )
                  .borderRadius({
                    topLeft: 5,
                    topRight: 5,
                    bottomLeft: 2,
                    bottomRight: 2
                  })

                Text(point.date.substring(5))
                  .fontSize(9)
                  .fontColor('#A8ABB2')
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 12 })
            }
          )
        }
      }
      .width('100%')
      .height(150)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Bottom)
      .padding({ top: 8 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .margin({
      left: 16,
      right: 16,
      top: 12
    })
  }

  @Builder
  buildRatingsSection(): void {
    Column() {
      this.buildSectionHeader(
        '综合评分',
        '汇总各平台评价表现'
      )

      Row() {
        Column() {
          Text(this.product!.aggregateScore.toString())
            .fontSize(54)
            .fontWeight(FontWeight.Bold)
            .fontColor('#5267E8')

          Text('综合指数')
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ top: 2 })
        }
        .width(112)
        .height(112)
        .backgroundColor('#F5F6FF')
        .borderRadius(18)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: 18 })

        Column() {
          this.buildStarDisplay(
            this.product!.aggregateRating
          )

          Text(
            this.product!.aggregateRating.toFixed(1) +
            ' 分'
          )
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1C1E')
            .margin({ top: 8 })

          Text(
            '共 ' +
            this.product!.totalReviewCount.toString() +
            ' 条评价'
          )
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 18 })

      Divider()
        .strokeWidth(0.5)
        .color('#ECEEF2')
        .margin({
          top: 2,
          bottom: 14
        })

      Text('各平台评分')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1C1E')
        .width('100%')
        .margin({ bottom: 8 })

      ForEach(
        this.product!.platformListings,
        (listing: PlatformListing) => {
          Row() {
            Text(listing.platform)
              .fontSize(13)
              .fontColor('#4C4F56')
              .width(64)

            Row() {
              ForEach(
                this.getStarDisplayChars(listing.rating),
                (ch: string) => {
                  Text(ch)
                    .fontSize(14)
                    .fontColor(
                      ch === '\u2605' ?
                      '#FF9500' :
                      '#D5D7DD'
                    )
                }
              )
            }

            Blank()

            Text(listing.rating.toFixed(1))
              .fontSize(13)
              .fontColor('#1C1C1E')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding({
            top: 7,
            bottom: 7
          })
        }
      )
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .margin({
      left: 16,
      right: 16,
      top: 12
    })
  }

  @Builder
  buildStarDisplay(rating: number): void {
    Row() {
      ForEach(
        this.getStarDisplayChars(rating),
        (ch: string) => {
          Text(ch)
            .fontSize(20)
            .fontColor(
              ch === '\u2605' ?
              '#FF9500' :
              '#D5D7DD'
            )
        }
      )
    }
  }

  @Builder
  buildReviewTags(): void {
    Column() {
      this.buildSectionHeader(
        '用户评价关键词',
        '快速了解常见评价重点'
      )

      if (this.positiveTags.length > 0) {
        Text('好评关键词')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6F737B')
          .width('100%')
          .margin({ bottom: 9 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(
            this.positiveTags,
            (tag: ReviewTag) => {
              this.buildTagChip(tag, 0)
            }
          )
        }
        .width('100%')
        .margin({ bottom: 14 })
      }

      if (this.negativeTags.length > 0) {
        Text('差评关键词')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6F737B')
          .width('100%')
          .margin({ bottom: 9 })

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(
            this.negativeTags,
            (tag: ReviewTag) => {
              this.buildTagChip(tag, 1)
            }
          )
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .margin({
      left: 16,
      right: 16,
      top: 12
    })
  }

  @Builder
  buildTagChip(
    tag: ReviewTag,
    tagType: number
  ): void {
    Text(
      tag.text +
      ' ' +
      tag.count.toString()
    )
      .fontSize(12)
      .fontColor(
        tagType === 0 ?
        '#2D8A4E' :
        '#D9485F'
      )
      .padding({
        left: 12,
        right: 12,
        top: 7,
        bottom: 7
      })
      .backgroundColor(
        tagType === 0 ?
        '#EEF9F1' :
        '#FFF1F3'
      )
      .borderRadius(15)
      .margin({
        right: 8,
        bottom: 8
      })
  }

  @Builder
  buildRadarChart(): void {
    Column() {
      this.buildSectionHeader(
        '商品画像',
        '六维综合评价'
      )

      if (this.radarDimensions.length >= 6) {
        Row() {
          RadarChart({
            dimensions: this.radarDimensions,
            chartSize: 300
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(18)
    .border({
      width: 1,
      color: '#ECEEF2'
    })
    .margin({
      left: 16,
      right: 16,
      top: 12
    })
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
    .margin({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
  }

  @Builder
  buildSectionHeader(
    title: string,
    subtitle: string
  ): void {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .width('100%')

      Text(subtitle)
        .fontSize(12)
        .fontColor('#8E8E93')
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 16 })
  }

  @Builder
  buildTopBar(
    title: string,
    showFavorite: boolean
  ): void {
    Row() {
      Column() {
        Image($r('app.media.detail_back'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
      .width(40)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        router.back();
      })

      Text(title)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .layoutWeight(1)
        .margin({ left: 2 })

      if (showFavorite) {
        Column() {
          Image(
            this.isFavorited ?
            $r('app.media.detail_favorite_active') :
            $r('app.media.detail_favorite')
          )
            .width(23)
            .height(23)
            .objectFit(ImageFit.Contain)
        }
        .width(42)
        .height(42)
        .borderRadius(13)
        .backgroundColor(
          this.isFavorited ?
          '#FFF1F0' :
          '#F7F8FA'
        )
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.toggleFavorite();
        })
      } else {
        Column()
          .width(42)
          .height(42)
      }
    }
    .width('100%')
    .height(64)
    .padding({
      left: 8,
      right: 14
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          this.buildTopBar('加载中...', false)

          Column() {
            ForEach(
              [0, 1, 2, 3],
              (item: number) => {
                Row()
                  .width('100%')
                  .height(120)
                  .backgroundColor('#E7E9EE')
                  .borderRadius(18)
                  .margin({
                    left: 16,
                    right: 16,
                    top: 12
                  })
              }
            )
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F5F6F8')
          .padding({ top: 8 })
        }
        .width('100%')
        .height('100%')
      } else if (this.product === undefined) {
        Column() {
          this.buildTopBar('商品详情', false)

          Column({ space: 14 }) {
            Column() {
              Image($r('app.media.detail_not_found'))
                .width(44)
                .height(44)
                .objectFit(ImageFit.Contain)
            }
            .width(78)
            .height(78)
            .borderRadius(24)
            .backgroundColor('#EEF1FF')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text('商品未找到')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')

            Text('商品可能已下架或暂时无法加载')
              .fontSize(13)
              .fontColor('#8E8E93')

            Button('返回上一页')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#5267E8')
              .borderRadius(13)
              .height(42)
              .padding({
                left: 26,
                right: 26
              })
              .margin({ top: 4 })
              .onClick(() => {
                router.back();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#F5F6F8')
        }
        .width('100%')
        .height('100%')
      } else {
        Column() {
          this.buildTopBar('商品详情', true)

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
            .padding({ bottom: 86 })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F5F6F8')
          .scrollBar(BarState.Off)

          Row({ space: 12 }) {
            Button('查看商品')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#5267E8')
              .borderRadius(14)
              .layoutWeight(1)
              .height(50)
              .onClick(() => {
                promptAction.showToast({
                  message: '跳转至商品详情'
                });
              })

            Button(
              this.isFavorited ?
              '已收藏' :
              '加入收藏'
            )
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(
                this.isFavorited ?
                '#5267E8' :
                '#5267E8'
              )
              .backgroundColor(
                this.isFavorited ?
                '#EEF1FF' :
                Color.White
              )
              .borderRadius(14)
              .border({
                width: 1,
                color: '#5267E8'
              })
              .layoutWeight(1)
              .height(50)
              .onClick(() => {
                this.toggleFavorite();
              })
          }
          .width('100%')
          .height(70)
          .padding({
            left: 16,
            right: 16,
            top: 10,
            bottom: 10
          })
          .backgroundColor(Color.White)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F6F8')
      }
    }
    .width('100%')
    .height('100%')
  }
}
