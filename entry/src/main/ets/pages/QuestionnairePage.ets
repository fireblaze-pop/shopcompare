import { router } from '@kit.ArkUI';
import { MockData } from '../data/MockData';
import { PreferenceManager } from '../utils/PreferenceManager';
import { UserProfile, Category } from '../models/DataModels';
import { DataProvider } from '../data/DataProvider';
import { BehaviorManager } from '../utils/BehaviorManager';
import { RecommendationEngine } from '../utils/RecommendationEngine';

interface BudgetCard {
  id: string;
  title: string;
  subtitle: string;
  icon: string;
}

interface PlatformItem {
  id: string;
  name: string;
}

let DIMENSION_LIST: string[] = [
  '价格优惠', '品质口碑', '品牌信赖',
  '售后服务', '物流速度', '外观设计'
];

let BUDGET_LIST: BudgetCard[] = [
  {
    id: 'thrifty',
    title: '精打细算型',
    subtitle: '更看重性价比，货比三家',
    icon: '🛒'
  },
  {
    id: 'balanced',
    title: '均衡实用型',
    subtitle: '在预算和品质间取得平衡',
    icon: '⚖️'
  },
  {
    id: 'quality',
    title: '品质优先型',
    subtitle: '愿意为品质支付溢价',
    icon: '💎'
  },
  {
    id: 'premium',
    title: '高端享受型',
    subtitle: '追求顶级体验，预算充足',
    icon: '👑'
  }
];

let PLATFORM_LIST: PlatformItem[] = [
  { id: 'taobao', name: '淘宝/天猫' },
  { id: 'jd', name: '京东' },
  { id: 'pdd', name: '拼多多' },
  { id: 'douyin', name: '抖音电商' },
  { id: 'xiaohongshu', name: '小红书' },
  { id: 'xianyu', name: '闲鱼' },
  { id: 'amazon', name: '亚马逊' },
  { id: 'suning', name: '苏宁易购' }
];

@Entry
@Component
struct QuestionnairePage {
  @State currentStep: number = 0;
  @State selectedPreferences: string[] = [];
  @State selectedDimensions: string[] = [];
  @State selectedBudget: string = '';
  @State selectedPlatforms: string[] = [];
  private categories: Category[] = MockData.getCategories();
  private dimensions: string[] = DIMENSION_LIST;
  private budgetOptions: BudgetCard[] = BUDGET_LIST;
  private platformItems: PlatformItem[] = PLATFORM_LIST;

  isPreferenceSelected(id: string): boolean {
    return this.selectedPreferences.indexOf(id) >= 0;
  }

  isDimensionSelected(dim: string): boolean {
    return this.selectedDimensions.indexOf(dim) >= 0;
  }

  isBudgetSelected(id: string): boolean {
    return this.selectedBudget === id;
  }

  isPlatformSelected(id: string): boolean {
    return this.selectedPlatforms.indexOf(id) >= 0;
  }

  togglePreference(id: string): void {
    let index: number = this.selectedPreferences.indexOf(id);
    if (index >= 0) {
      this.selectedPreferences.splice(index, 1);
    } else {
      this.selectedPreferences.push(id);
    }
  }

  toggleDimension(dim: string): void {
    let index: number = this.selectedDimensions.indexOf(dim);
    if (index >= 0) {
      this.selectedDimensions.splice(index, 1);
    } else {
      this.selectedDimensions.push(dim);
    }
  }

  selectBudget(id: string): void {
    this.selectedBudget = id;
  }

  togglePlatform(id: string): void {
    let index: number = this.selectedPlatforms.indexOf(id);
    if (index >= 0) {
      this.selectedPlatforms.splice(index, 1);
    } else {
      this.selectedPlatforms.push(id);
    }
  }

  isNextEnabled(): boolean {
    if (this.currentStep === 0) {
      return this.selectedPreferences.length > 0;
    }
    if (this.currentStep === 1) {
      return this.selectedDimensions.length > 0;
    }
    if (this.currentStep === 2) {
      return this.selectedBudget.length > 0;
    }
    return this.selectedPlatforms.length > 0;
  }

  goNext(): void {
    if (this.currentStep < 3) {
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.currentStep = this.currentStep + 1;
      });
    }
  }

  goPrev(): void {
    if (this.currentStep > 0) {
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.currentStep = this.currentStep - 1;
      });
    }
  }

  handleSkip(): void {
    router.replaceUrl({ url: 'pages/HomePage' });
  }

  async handleComplete(): Promise<void> {
    try {
      let prefNames: string[] = [];
      let ci: number = 0;
      while (ci < this.categories.length) {
        if (this.selectedPreferences.indexOf(this.categories[ci].id) >= 0) {
          prefNames.push(this.categories[ci].name);
        }
        ci = ci + 1;
      }
      let profile: UserProfile = {
        preferences: prefNames,
        dimensions: this.selectedDimensions,
        budget: this.selectedBudget,
        platforms: this.selectedPlatforms,
        isFirstLaunch: false
      };
      PreferenceManager.saveUserProfile(profile);
      PreferenceManager.setFirstLaunchDone();
      let candidates = DataProvider.getProductRepository().getProducts();
      BehaviorManager.getInstance().seedFromProfile(profile, candidates);
      RecommendationEngine.getInstance().refresh();
      router.replaceUrl({ url: 'pages/HomePage' });
    } catch (e) {
      router.replaceUrl({ url: 'pages/HomePage' });
    }
  }

  @Builder
  Step0Content() {
    Column() {
      Text('选择你感兴趣的品类')
        .fontSize(20)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .margin({ bottom: 4 });

      Text('我们将为你精准推荐')
        .fontSize(15)
        .fontColor('#8E8E93')
        .margin({ bottom: 24 });

      Grid() {
        ForEach(this.categories, (item: Category) => {
          GridItem() {
            Column() {
              Column() {
                Text(item.icon)
                  .fontSize(24);
              }
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor(this.isPreferenceSelected(item.id) ?
                'rgba(0, 122, 255, 0.1)' : '#F2F2F7')
              .border({
                width: this.isPreferenceSelected(item.id) ? 2 : 0,
                color: '#007AFF'
              })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.togglePreference(item.id);
              });

              Text(item.name)
                .fontSize(12)
                .fontColor('#3C3C3C')
                .margin({ top: 6 });
            }
            .alignItems(HorizontalAlign.Center);
          }
        }, (item: Category) => item.id)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(12)
      .width('100%');
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8 });
  }

  @Builder
  Step1Content() {
    Column() {
      Text('你最看重什么？')
        .fontSize(20)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .margin({ bottom: 4 });

      Text('可多选')
        .fontSize(15)
        .fontColor('#8E8E93')
        .margin({ bottom: 24 });

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.dimensions, (item: string) => {
          Text(item)
            .fontSize(14)
            .fontColor(this.isDimensionSelected(item) ? Color.White : '#1C1C1E')
            .backgroundColor(this.isDimensionSelected(item) ? '#007AFF' : '#F2F2F7')
            .borderRadius(20)
            .padding({ left: 18, right: 18, top: 10, bottom: 10 })
            .margin({ right: 10, bottom: 12 })
            .onClick(() => {
              this.toggleDimension(item);
            });
        }, (item: string) => item)
      }
      .width('100%');
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8 });
  }

  @Builder
  Step2Content() {
    Column() {
      Text('你的预算定位是？')
        .fontSize(20)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .margin({ bottom: 24 });

      ForEach(this.budgetOptions, (item: BudgetCard) => {
        Row() {
          Text(item.icon)
            .fontSize(32);

          Column() {
            Text(item.title)
              .fontSize(16)
              .fontWeight(600)
              .fontColor('#1C1C1E');

            Text(item.subtitle)
              .fontSize(13)
              .fontColor('#8E8E93')
              .margin({ top: 4 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 14 });
        }
        .width('100%')
        .padding(16)
        .borderRadius(12)
        .backgroundColor(this.isBudgetSelected(item.id) ?
          'rgba(0, 122, 255, 0.05)' : '#FFFFFF')
        .border({
          width: this.isBudgetSelected(item.id) ? 2 : 1,
          color: this.isBudgetSelected(item.id) ? '#007AFF' : '#E5E5EA'
        })
        .margin({ bottom: 12 })
        .onClick(() => {
          this.selectBudget(item.id);
        });
      }, (item: BudgetCard) => item.id);
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8 });
  }

  @Builder
  Step3Content() {
    Column() {
      Text('你常用的购物平台？')
        .fontSize(20)
        .fontWeight(600)
        .fontColor('#1C1C1E')
        .margin({ bottom: 4 });

      Text('可多选')
        .fontSize(15)
        .fontColor('#8E8E93')
        .margin({ bottom: 24 });

      ForEach(this.platformItems, (item: PlatformItem) => {
        Row() {
          Column() {
            if (this.isPlatformSelected(item.id)) {
              Text('\u2713')
                .fontSize(14)
                .fontColor(Color.White);
            }
          }
          .width(22)
          .height(22)
          .borderRadius(4)
          .backgroundColor(this.isPlatformSelected(item.id) ?
            '#007AFF' : Color.Transparent)
          .border({
            width: this.isPlatformSelected(item.id) ? 0 : 1.5,
            color: '#D1D1D6'
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Text(item.name)
            .fontSize(15)
            .fontColor('#1C1C1E')
            .margin({ left: 12 });
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .borderRadius(12)
        .backgroundColor('#FFFFFF')
        .margin({ bottom: 8 })
        .onClick(() => {
          this.togglePlatform(item.id);
        });
      }, (item: PlatformItem) => item.id);
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8 });
  }

  build() {
    Column() {
      Row() {
        Row() {
          ForEach(['0', '1', '2', '3'], (item: string, index: number) => {
            Text(index <= this.currentStep ? '\u25CF' : '\u25CB')
              .fontSize(10)
              .fontColor(index <= this.currentStep ? '#007AFF' : '#D1D1D6')
              .margin({ left: 3, right: 3 });
          }, (item: string) => item)
        }

        Blank()

        Button('跳过')
          .fontSize(14)
          .fontColor('#8E8E93')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.handleSkip();
          });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 });

      Scroll() {
        Column() {
          if (this.currentStep === 0) {
            this.Step0Content();
          } else if (this.currentStep === 1) {
            this.Step1Content();
          } else if (this.currentStep === 2) {
            this.Step2Content();
          } else {
            this.Step3Content();
          }

          Column()
            .width('100%')
            .height(80);
        }
        .width('100%');
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off);

      Row() {
        if (this.currentStep > 0) {
          Button('上一步')
            .fontSize(15)
            .fontColor('#007AFF')
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: '#007AFF' })
            .borderRadius(22)
            .height(48)
            .layoutWeight(1)
            .margin({ right: 12 })
            .onClick(() => {
              this.goPrev();
            });
        }

        if (this.currentStep < 3) {
          Button('下一步')
            .fontSize(15)
            .fontWeight(600)
            .fontColor(Color.White)
            .backgroundColor(this.isNextEnabled() ? '#007AFF' : '#8E8E93')
            .borderRadius(22)
            .height(48)
            .layoutWeight(1)
            .margin({ left: this.currentStep > 0 ? 12 : 0 })
            .enabled(this.isNextEnabled())
            .onClick(() => {
              this.goNext();
            });
        } else {
          Button('完成')
            .fontSize(15)
            .fontWeight(600)
            .fontColor(Color.White)
            .backgroundColor(this.isNextEnabled() ? '#007AFF' : '#8E8E93')
            .borderRadius(22)
            .height(48)
            .layoutWeight(1)
            .margin({ left: 12 })
            .enabled(this.isNextEnabled())
            .onClick(() => {
              this.handleComplete();
            });
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 20 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7');
  }
}
