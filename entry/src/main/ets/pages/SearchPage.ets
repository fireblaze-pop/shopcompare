import { router } from '@kit.ArkUI';
import { Product } from '../models/DataModels';
import { MockData } from '../data/MockData';
import { NavParams } from '../utils/PreferenceManager';
import { PreferenceManager } from '../utils/PreferenceManager';
import { BehaviorManager } from '../utils/BehaviorManager';
import { DataProvider } from '../data/DataProvider';
import { HttpClient } from '../utils/HttpClient';

interface SearchResult {
  items: Product[]
  total: number
}

@Entry
@Component
struct SearchPage {
  @State searchText: string = '';
  @State searchResults: Product[] = [];
  @State searchHistory: string[] = [];
  @State hotKeywords: string[] = [];
  @State showHistory: boolean = true;
  private http: HttpClient = DataProvider.getHttpClient()

  aboutToAppear(): void {
    this.hotKeywords = MockData.getHotSearchKeywords();
    this.searchHistory = PreferenceManager.getSearchHistory();
  }

  async doSearch(keyword: string): Promise<void> {
    this.searchText = keyword
    if (keyword.length === 0) {
      this.searchResults = []
      return
    }
    try {
      let resp = await this.http.get('/search?q=' + keyword)
      if (resp.statusCode === 200) {
        let data: SearchResult = JSON.parse(resp.data) as SearchResult
        this.searchResults = data.items
        return
      }
    } catch (e) {
    }
    // 降级: 本地搜索
    this.searchLocally(keyword)
  }

  searchLocally(keyword: string): void {
    let allProducts: Product[] = MockData.getProducts();
    let results: Product[] = [];
    let i: number = 0;
    while (i < allProducts.length) {
      let product: Product = allProducts[i];
      let name: string = product.name.toLowerCase();
      let brand: string = product.brand.toLowerCase();
      let kw: string = keyword.toLowerCase();
      if (name.indexOf(kw) >= 0 || brand.indexOf(kw) >= 0) {
        results.push(product);
      }
      i = i + 1;
    }
    this.searchResults = results;
  }

  commitSearch(keyword: string): void {
    this.doSearch(keyword);
    if (keyword.length > 0) {
      PreferenceManager.addSearchKeyword(keyword);
      BehaviorManager.getInstance().recordSearch(keyword);
      this.searchHistory = PreferenceManager.getSearchHistory();
    }
  }

  clearHistory(): void {
    PreferenceManager.clearSearchHistory();
    this.searchHistory = PreferenceManager.getSearchHistory();
  }

  navigateToDetail(product: Product): void {
    NavParams.productId = product.id;
    router.pushUrl({
      url: 'pages/ProductDetailPage'
    });
  }

  @Builder
  buildProductItem(product: Product): void {
    Row() {
      Column() {
        if (product.imageUrl.length > 0) {
          Image(product.imageUrl)
            .width(64)
            .height(64)
            .objectFit(ImageFit.Cover)
        }
        if (product.imageUrl.length === 0) {
          Text('\uD83D\uDCE6')
            .fontSize(32)
        }
      }
      .width(64)
      .height(64)
      .borderRadius(8)
      .backgroundColor('#F2F2F7')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text(product.name)
          .fontSize(15)
          .fontWeight(500)
          .fontColor('#1C1C1E')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Text(product.brand)
            .fontSize(12)
            .fontColor('#8E8E93')
          Text(' \u00B7 ' + product.category)
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .margin({ top: 4 })

        Row() {
          Text('\u00A5' + product.lowestPrice.toFixed(0))
            .fontSize(16)
            .fontWeight(700)
            .fontColor('#FF3B30')
          Text('起')
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ left: 4 })
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 6, bottom: 0 })
    .onClick(() => {
      this.navigateToDetail(product);
    })
  }

  build() {
    Column() {
      // 顶部搜索区域
      Row({ space: 8 }) {
        // 返回按钮
        Text('‹')
          .fontSize(34)
          .fontColor('#1C1C1E')
          .width(32)
          .height(46)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        // 搜索输入框
        Row() {
          Text('\uD83D\uDD0D')
            .fontSize(16)
            .margin({ left: 12 })

          TextInput({
            placeholder: '搜商品、品牌或型号',
            text: this.searchText
          })
            .fontSize(14)
            .fontColor('#1C1C1E')
            .placeholderColor('#8E8E93')
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .height(44)
            .padding({ left: 8, right: 4 })
            .onChange((value: string) => {
              this.searchText = value;
              this.doSearch(value);
            })
            .onSubmit(() => {
              this.commitSearch(this.searchText);
            })

          if (this.searchText.length > 0) {
            Text('\u2715')
              .fontSize(12)
              .fontColor('#8E8E93')
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .borderRadius(12)
              .backgroundColor('#E5E5EA')
              .margin({ right: 8 })
              .onClick(() => {
                this.searchText = '';
                this.searchResults = [];
              })
          }
        }
        .layoutWeight(1)
        .height(44)
        .borderRadius(14)
        .backgroundColor('#F5F6F8')
        .alignItems(VerticalAlign.Center)

        // 搜索按钮
        Button('搜索')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#5267E8')
          .width(60)
          .height(40)
          .borderRadius(12)
          .onClick(() => {
            this.commitSearch(this.searchText);
          })
      }
      .width('100%')
      .height(64)
      .padding({ left: 10, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      // 搜索结果
      if (this.searchResults.length > 0) {
        Scroll() {
          Column() {
            Text('搜索结果（' + this.searchResults.length.toString() + '）')
              .fontSize(13)
              .fontColor('#8E8E93')
              .width('100%')
              .padding({
                left: 16,
                top: 12,
                bottom: 8
              })

            ForEach(this.searchResults, (product: Product) => {
              this.buildProductItem(product)
            })
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F6F8')
        .scrollBar(BarState.Off)
      } else {
        Column() {
          // 搜索历史
          Column() {
            Row() {
              Text('搜索历史')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1C1C1E')
                .layoutWeight(1)

              Text(this.showHistory ? '隐藏' : '展开')
                .fontSize(13)
                .fontColor('#5267E8')
                .padding({
                  left: 8,
                  right: 8,
                  top: 6,
                  bottom: 6
                })
                .onClick(() => {
                  this.showHistory = !this.showHistory;
                })

              if (this.searchHistory.length > 0) {
                Text('清空')
                  .fontSize(13)
                  .fontColor('#8E8E93')
                  .padding({
                    left: 8,
                    top: 6,
                    bottom: 6
                  })
                  .onClick(() => {
                    this.clearHistory();
                  })
              }
            }
            .width('100%')
            .padding({
              left: 16,
              right: 16,
              top: 20,
              bottom: this.showHistory ? 12 : 4
            })

            if (this.showHistory) {
              if (this.searchHistory.length > 0) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.searchHistory, (keyword: string) => {
                    Text(keyword)
                      .fontSize(13)
                      .fontColor('#3C3C3C')
                      .padding({
                        left: 14,
                        right: 14,
                        top: 8,
                        bottom: 8
                      })
                      .backgroundColor(Color.White)
                      .borderRadius(16)
                      .margin({
                        right: 10,
                        bottom: 10
                      })
                      .onClick(() => {
                        this.commitSearch(keyword);
                      })
                  })
                }
                .padding({
                  left: 16,
                  right: 6
                })
                .width('100%')
              } else {
                Text('暂无搜索记录')
                  .fontSize(13)
                  .fontColor('#AEAEB2')
                  .width('100%')
                  .padding({
                    left: 16,
                    bottom: 8
                  })
              }
            }
          }
          .width('100%')

          // 热门搜索
          Column() {
            Text('热门搜索')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')
              .width('100%')
              .padding({
                left: 16,
                top: this.showHistory ? 16 : 8,
                bottom: 12
              })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.hotKeywords, (keyword: string) => {
                Text(keyword)
                  .fontSize(13)
                  .fontColor('#3C3C3C')
                  .padding({
                    left: 14,
                    right: 14,
                    top: 8,
                    bottom: 8
                  })
                  .backgroundColor(Color.White)
                  .borderRadius(16)
                  .margin({
                    right: 10,
                    bottom: 10
                  })
                  .onClick(() => {
                    this.commitSearch(keyword);
                  })
              })
            }
            .padding({
              left: 16,
              right: 6
            })
            .width('100%')
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor('#F5F6F8')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
