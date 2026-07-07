@Component
export struct SearchKeywordPanel {
  @Prop searchHistory: string[] = []
  @Prop hotKeywords: string[] = []
  @Prop showHistory: boolean = true

  onToggleHistory: () => void = (): void => {}
  onClearHistory: () => void = (): void => {}
  onKeywordClick: (keyword: string) => void =
    (keyword: string): void => {}

  build() {
    Column() {
      Column() {
        Row() {
          Text('搜索历史')
            .fontSize(18)
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
              this.onToggleHistory()
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
                this.onClearHistory()
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
            Flex({
              wrap: FlexWrap.Wrap
            }) {
              ForEach(
                this.searchHistory,
                (keyword: string) => {
                  this.KeywordChip(keyword)
                }
              )
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

      Column() {
        Text('热门搜索')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .width('100%')
          .padding({
            left: 16,
            top: this.showHistory ? 16 : 8,
            bottom: 12
          })

        Flex({
          wrap: FlexWrap.Wrap
        }) {
          ForEach(
            this.hotKeywords,
            (keyword: string) => {
              this.KeywordChip(keyword)
            }
          )
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
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#F5F6F8')
  }

  @Builder KeywordChip(keyword: string) {
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
      .border({
        width: 1,
        color: '#ECEEF2'
      })
      .borderRadius(18)
      .margin({
        right: 10,
        bottom: 10
      })
      .onClick(() => {
        this.onKeywordClick(keyword)
      })
  }
}
