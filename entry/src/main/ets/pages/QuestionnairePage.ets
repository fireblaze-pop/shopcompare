import { NavRouter } from '../utils/NavRouter'
import { PreferenceManager } from '../utils/PreferenceManager'
import { UserProfile, Category, Product } from '../models/DataModels'
import { BehaviorManager } from '../utils/BehaviorManager'
import { RecommendationEngine } from '../utils/RecommendationEngine'
import { DataProvider } from '../data/DataProvider'

interface BudgetCard {
  id: string
  title: string
  subtitle: string
  mark: string
}

let BUDGET_LIST: BudgetCard[] = [
  {
    id: 'thrifty',
    title: '精打细算型',
    subtitle: '优先控制预算，更看重价格',
    mark: '￥'
  },
  {
    id: 'balanced',
    title: '均衡实用型',
    subtitle: '在预算和品质之间取得平衡',
    mark: '≈'
  },
  {
    id: 'quality',
    title: '品质优先型',
    subtitle: '愿意为品质和口碑支付溢价',
    mark: '↑'
  },
  {
    id: 'premium',
    title: '高端享受型',
    subtitle: '优先选择高端定位和完整体验',
    mark: '◆'
  }
]

@Entry
@Component
struct QuestionnairePage {
  @State currentStep: number = 0
  @State selectedPreferences: string[] = []
  @State selectedBudget: string = ''
  @State isFirstLaunchFlow: boolean = true

  private categories: Category[] =
    DataProvider.getProductRepository().getCategories()

  private budgetOptions: BudgetCard[] = BUDGET_LIST

  aboutToAppear(): void {
    this.isFirstLaunchFlow = PreferenceManager.isFirstLaunch()

    let profile: UserProfile =
      PreferenceManager.loadUserProfile()

    if (!this.isFirstLaunchFlow) {
      this.selectedPreferences =
        this.categoryNamesToIds(profile.preferences)
      this.selectedBudget = profile.budget
    }
  }

  copyStringArray(source: string[]): string[] {
    let result: string[] = []
    let i: number = 0

    while (i < source.length) {
      result.push(source[i])
      i = i + 1
    }

    return result
  }

  categoryNamesToIds(names: string[]): string[] {
    let ids: string[] = []
    let i: number = 0

    while (i < this.categories.length) {
      if (names.indexOf(this.categories[i].name) >= 0) {
        ids.push(this.categories[i].id)
      }
      i = i + 1
    }

    return ids
  }

  isPreferenceSelected(id: string): boolean {
    return this.selectedPreferences.indexOf(id) >= 0
  }

  isBudgetSelected(id: string): boolean {
    return this.selectedBudget === id
  }

  togglePreference(id: string): void {
    let next: string[] = []
    let exists: boolean =
      this.selectedPreferences.indexOf(id) >= 0

    let i: number = 0
    while (i < this.selectedPreferences.length) {
      if (this.selectedPreferences[i] !== id) {
        next.push(this.selectedPreferences[i])
      }
      i = i + 1
    }

    if (!exists && next.length < 3) {
      next.push(id)
    }

    this.selectedPreferences = next
  }

  selectBudget(id: string): void {
    this.selectedBudget = id
  }

  isNextEnabled(): boolean {
    if (this.currentStep === 0) {
      return this.selectedPreferences.length > 0
    }

    return this.selectedBudget.length > 0
  }

  goNext(): void {
    if (this.currentStep < 1) {
      animateTo({
        duration: 260,
        curve: Curve.EaseInOut
      }, () => {
        this.currentStep = this.currentStep + 1
      })
    }
  }

  goPrev(): void {
    if (this.currentStep > 0) {
      animateTo({
        duration: 260,
        curve: Curve.EaseInOut
      }, () => {
        this.currentStep = this.currentStep - 1
      })
    } else if (!this.isFirstLaunchFlow) {
      NavRouter.back()
    }
  }

  handleSkip(): void {
    if (!this.isFirstLaunchFlow) {
      NavRouter.back()
      return
    }

    let profile: UserProfile = {
      preferences: [],
      dimensions: [],
      budget: '',
      platforms: [],
      isFirstLaunch: false
    }

    PreferenceManager.saveUserProfile(profile)
    PreferenceManager.setFirstLaunchDone()

    NavRouter.replace('HomePage')
  }

  async handleComplete(): Promise<void> {
    try {
      let prefNames: string[] = []
      let ci: number = 0

      while (ci < this.categories.length) {
        if (
          this.selectedPreferences.indexOf(
            this.categories[ci].id
          ) >= 0
        ) {
          prefNames.push(this.categories[ci].name)
        }
        ci = ci + 1
      }

      let oldProfile: UserProfile =
        PreferenceManager.loadUserProfile()

      let profile: UserProfile = {
        preferences: prefNames,
        dimensions:
          this.copyStringArray(oldProfile.dimensions),
        budget: this.selectedBudget,
        platforms:
          this.copyStringArray(oldProfile.platforms),
        isFirstLaunch: false
      }

      PreferenceManager.saveUserProfile(profile)
      PreferenceManager.setFirstLaunchDone()

      let candidates: Product[] =
        DataProvider
          .getProductRepository()
          .getProducts()

      BehaviorManager
        .getInstance()
        .seedFromProfile(profile, candidates)

      RecommendationEngine.getInstance().refresh()

      if (this.isFirstLaunchFlow) {
        NavRouter.replace('HomePage')
      } else {
        NavRouter.back()
      }
    } catch (e) {
      if (this.isFirstLaunchFlow) {
        NavRouter.replace('HomePage')
      } else {
        NavRouter.back()
      }
    }
  }

  getCategoryCountText(): string {
    return this.selectedPreferences.length.toString() + ' / 3'
  }

  @Builder StepProgress() {
    Row({ space: 8 }) {
      ForEach(['0', '1'], (
        item: string,
        index: number
      ) => {
        Column()
          .height(4)
          .layoutWeight(1)
          .borderRadius(2)
          .backgroundColor(
            index <= this.currentStep ?
              '#5267E8' :
              '#E2E5EA'
          )
      }, (item: string) => item)
    }
    .width('100%')
  }

  @Builder CategoryIcon(name: string) {
    if (name === '手机数码') {
      Image($r('app.media.category_phone'))
        .width(28)
        .height(28)
        .objectFit(ImageFit.Contain)
    } else if (name === '电脑办公') {
      Image($r('app.media.category_laptop'))
        .width(28)
        .height(28)
        .objectFit(ImageFit.Contain)
    } else if (name === '家用电器') {
      Image($r('app.media.category_appliance'))
        .width(28)
        .height(28)
        .objectFit(ImageFit.Contain)
    } else if (name === '美妆个护') {
      Image($r('app.media.category_beauty'))
        .width(28)
        .height(28)
        .objectFit(ImageFit.Contain)
    } else if (name === '服饰鞋包') {
      Image($r('app.media.category_clothing'))
        .width(28)
        .height(28)
        .objectFit(ImageFit.Contain)
    } else {
      Image($r('app.media.category_food'))
        .width(28)
        .height(28)
        .objectFit(ImageFit.Contain)
    }
  }

  @Builder Step0Content() {
    Column() {
      Row() {
        Column({ space: 5 }) {
          Text('选择你感兴趣的品类')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')

          Text('最多选择 3 个，用于首页初始推荐')
            .fontSize(13)
            .fontColor('#8E8E93')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.getCategoryCountText())
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5267E8')
          .padding({
            left: 10,
            right: 10,
            top: 6,
            bottom: 6
          })
          .backgroundColor('#EEF1FF')
          .borderRadius(10)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 22 })

      Grid() {
        ForEach(this.categories, (item: Category) => {
          GridItem() {
            Column({ space: 10 }) {
              Row() {
                Column() {
                  this.CategoryIcon(item.name)
                }
                .width(50)
                .height(50)
                .borderRadius(16)
                .backgroundColor(
                  this.isPreferenceSelected(item.id) ?
                    Color.White :
                    '#F5F6F8'
                )
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)

                Blank()

                Column() {
                  if (this.isPreferenceSelected(item.id)) {
                    Text('✓')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                  }
                }
                .width(22)
                .height(22)
                .borderRadius(11)
                .backgroundColor(
                  this.isPreferenceSelected(item.id) ?
                    '#5267E8' :
                    '#E7E9EE'
                )
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')

              Text(item.name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1C1C1E')
                .width('100%')
            }
            .width('100%')
            .padding(15)
            .backgroundColor(
              this.isPreferenceSelected(item.id) ?
                '#EEF1FF' :
                Color.White
            )
            .borderRadius(16)
            .border({
              width: 1,
              color:
                this.isPreferenceSelected(item.id) ?
                  '#5267E8' :
                  '#ECEEF2'
            })
            .onClick(() => {
              this.togglePreference(item.id)
            })
          }
        }, (item: Category) => item.id)
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')

      Column({ space: 5 }) {
        Text('这些选择会做什么？')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1C1E')
          .width('100%')

        Text('首次使用时优先展示你关注的品类；之后浏览、收藏等行为会继续校准推荐结果。')
          .fontSize(13)
          .fontColor('#8E8E93')
          .lineHeight(20)
          .width('100%')
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#EEF1FF')
      .borderRadius(14)
      .margin({ top: 18 })
    }
    .width('100%')
  }

  @Builder Step1Content() {
    Column() {
      Column({ space: 5 }) {
        Text('选择你的预算偏好')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Text('用于匹配更符合预算定位的初始推荐')
          .fontSize(13)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 22 })

      ForEach(this.budgetOptions, (item: BudgetCard) => {
        Row() {
          Column() {
            Text(item.mark)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(
                this.isBudgetSelected(item.id) ?
                  '#5267E8' :
                  '#7C7F87'
              )
          }
          .width(48)
          .height(48)
          .borderRadius(15)
          .backgroundColor(
            this.isBudgetSelected(item.id) ?
              Color.White :
              '#F5F6F8'
          )
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column({ space: 4 }) {
            Text(item.title)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')

            Text(item.subtitle)
              .fontSize(13)
              .fontColor('#8E8E93')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 13 })

          Column() {
            if (this.isBudgetSelected(item.id)) {
              Text('✓')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
          }
          .width(22)
          .height(22)
          .borderRadius(11)
          .backgroundColor(
            this.isBudgetSelected(item.id) ?
              '#5267E8' :
              '#E7E9EE'
          )
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding(15)
        .backgroundColor(
          this.isBudgetSelected(item.id) ?
            '#EEF1FF' :
            Color.White
        )
        .borderRadius(16)
        .border({
          width: 1,
          color:
            this.isBudgetSelected(item.id) ?
              '#5267E8' :
              '#ECEEF2'
        })
        .margin({ bottom: 12 })
        .onClick(() => {
          this.selectBudget(item.id)
        })
      }, (item: BudgetCard) => item.id)
    }
    .width('100%')
  }

  build() {
    Column() {
      Column({ space: 14 }) {
        Row() {
          if (
            this.currentStep > 0 ||
            !this.isFirstLaunchFlow
          ) {
            Image($r('app.media.icon_back'))
              .width(22)
              .height(22)
              .objectFit(ImageFit.Contain)
              .onClick(() => {
                this.goPrev()
              })
          } else {
            Column()
              .width(22)
              .height(22)
          }

          Text('个性化偏好')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .margin({ left: 12 })

          Blank()

          if (this.isFirstLaunchFlow) {
            Text('跳过')
              .fontSize(14)
              .fontColor('#8E8E93')
              .onClick(() => {
                this.handleSkip()
              })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        this.StepProgress()
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 16,
        bottom: 14
      })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          if (this.currentStep === 0) {
            this.Step0Content()
          } else {
            this.Step1Content()
          }
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 26,
          bottom: 30
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Row() {
        if (this.currentStep > 0) {
          Button('上一步')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#5267E8')
            .backgroundColor(Color.White)
            .border({ width: 1, color: '#5267E8' })
            .borderRadius(14)
            .height(50)
            .layoutWeight(1)
            .margin({ right: 12 })
            .onClick(() => {
              this.goPrev()
            })
        }

        Button(
          this.currentStep === 0 ?
            '下一步' :
            '保存偏好'
        )
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor(
            this.isNextEnabled() ?
              '#5267E8' :
              '#CDD1D8'
          )
          .borderRadius(14)
          .height(50)
          .layoutWeight(1)
          .enabled(this.isNextEnabled())
          .onClick(() => {
            if (this.currentStep === 0) {
              this.goNext()
            } else {
              this.handleComplete()
            }
          })
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 12,
        bottom: 18
      })
      .backgroundColor(Color.White)
      .border({
        width: { top: 0.5 },
        color: '#ECEEF2'
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }
}
