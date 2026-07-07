import { router } from '@kit.ArkUI'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { MockData } from '../../data/MockData'
import { PreferenceManager } from '../../utils/PreferenceManager'
import { BehaviorManager } from '../../utils/BehaviorManager'
import { ProfileHeaderCard } from './ProfileHeaderCard'
import { ProfileMenuItem } from './ProfileMenuItem'

@Component
export struct ProfileContent {
  onSwitchTab: (index: number) => void =
    (index: number): void => {}

  @State darkModeEnabled: boolean = false
  @State notificationEnabled: boolean = true
  @State favoriteCount: number = 0

  aboutToAppear(): void {
    this.darkModeEnabled = PreferenceManager.getDarkMode()
    this.notificationEnabled =
      PreferenceManager.getNotificationEnabled()
    this.favoriteCount =
      PreferenceManager.getFavoriteIds().length
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          ProfileHeaderCard({
            compareCount: MockData.getProductCount(),
            favoriteCount: this.favoriteCount
          })
            .margin({
              left: 16,
              right: 16,
              top: 18,
              bottom: 22
            })

          this.SectionTitle('我的服务')

          Column() {
            ProfileMenuItem({
              iconIndex: 0,
              label: '偏好管理',
              onItemAction: (): void => {
                router.pushUrl({
                  url: 'pages/QuestionnairePage'
                })
              }
            })

            this.MenuDivider()

            ProfileMenuItem({
              iconIndex: 1,
              label: '我的收藏',
              onItemAction: (): void => {
                this.onSwitchTab(2)
              }
            })

            this.MenuDivider()

            ProfileMenuItem({
              iconIndex: 2,
              label: '浏览历史',
              onItemAction: (): void => {
                router.pushUrl({
                  url: 'pages/BrowseHistoryPage'
                })
              }
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({
            left: 16,
            right: 16,
            bottom: 22
          })
          .clip(true)

          this.SectionTitle('设置')

          Column() {
            ProfileMenuItem({
              iconIndex: 3,
              label: '深色模式',
              hasToggle: true,
              toggleValue: this.darkModeEnabled,
              onToggleChange: (value: boolean): void => {
                this.handleDarkModeChange(value)
              }
            })

            this.MenuDivider()

            ProfileMenuItem({
              iconIndex: 4,
              label: '通知设置',
              hasToggle: true,
              toggleValue: this.notificationEnabled,
              onToggleChange: (value: boolean): void => {
                this.notificationEnabled = value
                PreferenceManager.setNotificationEnabled(value)
              }
            })

            this.MenuDivider()

            ProfileMenuItem({
              iconIndex: 5,
              label: '关于我们',
              showVersion: true,
              onItemAction: (): void => {
                router.pushUrl({
                  url: 'pages/AboutPage'
                })
              }
            })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({
            left: 16,
            right: 16,
            bottom: 24
          })
          .clip(true)

          Button('退出登录')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF3B30')
            .backgroundColor(Color.White)
            .width('100%')
            .height(50)
            .borderRadius(14)
            .margin({
              left: 16,
              right: 16,
              bottom: 28
            })
            .onClick(() => {
              this.logout()
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  @Builder SectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#7C7F87')
      .width('100%')
      .padding({
        left: 18,
        bottom: 10
      })
  }

  @Builder MenuDivider() {
    Divider()
      .strokeWidth(0.5)
      .color('#ECEEF2')
      .margin({
        left: 62,
        right: 14
      })
  }

  private handleDarkModeChange(value: boolean): void {
    this.darkModeEnabled = value
    PreferenceManager.setDarkMode(value)

    let context: common.UIAbilityContext =
      getContext(this) as common.UIAbilityContext

    let appContext = context.getApplicationContext()

    if (value) {
      appContext.setColorMode(
        ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      )
    } else {
      appContext.setColorMode(
        ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
      )
    }
  }

  private logout(): void {
    PreferenceManager.setDarkMode(false)
    PreferenceManager.setNotificationEnabled(true)
    PreferenceManager.saveUserProfile({
      preferences: [],
      dimensions: [],
      budget: '',
      platforms: [],
      isFirstLaunch: true
    })

    BehaviorManager.getInstance().clearActions()

    router.replaceUrl({
      url: 'pages/LoginPage'
    })
  }
}
