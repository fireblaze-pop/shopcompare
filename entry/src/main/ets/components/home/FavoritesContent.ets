import { NavRouter } from '../../utils/NavRouter'
import { Product } from '../../models/DataModels'
import { DataProvider } from '../../data/DataProvider'
import { NavParams, PreferenceManager } from '../../utils/PreferenceManager'
import { FavoriteProductCard } from './FavoriteProductCard'

interface DetailParams {
  productId: string
}

@Component
export struct FavoritesContent {
  @Prop @Watch('onVersionChange') favoritesVersion: number = 0
  @State favoriteProducts: Product[] = []

  aboutToAppear(): void {
    this.loadFavorites()
  }

  onVersionChange(): void {
    this.loadFavorites()
  }

  private loadFavorites(): void {
    let ids: string[] = PreferenceManager.getFavoriteIds()
    let allProducts: Product[] = DataProvider.getProductRepository().getProducts()
    let filtered: Product[] = []

    let i: number = 0

    while (i < allProducts.length) {
      let product: Product = allProducts[i]
      let found: boolean = false
      let j: number = 0

      while (j < ids.length) {
        if (ids[j] === product.id) {
          found = true
          break
        }

        j = j + 1
      }

      if (found) {
        filtered.push(product)
      }

      i = i + 1
    }

    this.favoriteProducts = filtered
  }

  @Builder DeleteSwipeBuilder() {
    Column({ space: 6 }) {
      Image($r('app.media.icon_unfavorite'))
        .width(22)
        .height(22)
        .objectFit(ImageFit.Contain)

      Text('取消收藏')
        .fontSize(13)
        .fontColor(Color.White)
    }
    .width(96)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FF4D4F')
  }

  build() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text('我的收藏')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text(
            '已收藏 ' +
            this.favoriteProducts.length.toString() +
            ' 件商品'
          )
            .fontSize(13)
            .fontColor('#8E8E93')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text('左滑也可快速取消')
          .fontSize(12)
          .fontColor('#A2A5AC')
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 18,
        bottom: 16
      })

      if (this.favoriteProducts.length === 0) {
        Column({ space: 14 }) {
          Column() {
            Image($r('app.media.empty_favorite'))
              .width(42)
              .height(42)
              .objectFit(ImageFit.Contain)
          }
          .width(76)
          .height(76)
          .borderRadius(24)
          .backgroundColor('#EEF1FF')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Text('还没有收藏商品')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1C1E')

          Text('看到喜欢的商品时，收藏后可以随时回来比价')
            .fontSize(13)
            .fontColor('#8E8E93')
            .textAlign(TextAlign.Center)
            .maxLines(2)

          Button('去搜索商品')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor('#5267E8')
            .height(42)
            .padding({
              left: 28,
              right: 28
            })
            .borderRadius(13)
            .onClick(() => {
              NavRouter.push('SearchPage')
            })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: 36,
          right: 36
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(
            this.favoriteProducts,
            (product: Product) => {
              ListItem() {
                FavoriteProductCard({
                  product: product,
                  onViewCompare: (selected: Product): void => {
                    this.navigateToDetail(selected)
                  },
                  onRemoveFavorite: (selected: Product): void => {
                    this.removeFavorite(selected.id)
                  }
                })
                  .margin({
                    left: 16,
                    right: 16
                  })
              }
              .swipeAction({
                end: {
                  builder: () => {
                    this.DeleteSwipeBuilder()
                  },
                  onAction: () => {
                    this.removeFavorite(product.id)
                  }
                }
              })
            },
            (product: Product) => product.id
          )
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          bottom: 18
        })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  private navigateToDetail(product: Product): void {
    NavParams.productId = product.id
    let params: DetailParams = { productId: product.id }
    NavRouter.push('ProductDetailPage', params)
  }

  private removeFavorite(productId: string): void {
    PreferenceManager.removeFavorite(productId)

    let newArr: Product[] = []
    let i: number = 0

    while (i < this.favoriteProducts.length) {
      if (this.favoriteProducts[i].id !== productId) {
        newArr.push(this.favoriteProducts[i])
      }

      i = i + 1
    }

    this.favoriteProducts = newArr
  }
}
