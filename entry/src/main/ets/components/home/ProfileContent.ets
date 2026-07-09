import { router, promptAction } from '@kit.ArkUI'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { PreferenceManager } from '../../utils/PreferenceManager'
import { BehaviorManager } from '../../utils/BehaviorManager'
import { LocalUserInfo, UserProfile } from '../../models/DataModels'
import { ProfileHeaderCard } from './ProfileHeaderCard'
import { ProfileMenuItem } from './ProfileMenuItem'

@Component
export struct ProfileContent {
  onSwitchTab: (index: number) => void =
    (index: number): void => {}

  @State darkModeEnabled: boolean = false
  @State notificationEnabled: boolean = true
  @State favoriteCount: number = 0
  @State preferenceCount: number = 0
  @State nickname: string = '购物达人'
  @State bio: string = '让每一次比价都更聪明'
  @State showEditProfile: boolean = false
  @State editNickname: string = ''
  @State editBio: string = ''

  aboutToAppear(): void {
    this.refreshProfile()
  }

  refreshProfile(): void {
    this.darkModeEnabled = PreferenceManager.getDarkMode()
    this.notificationEnabled =
      PreferenceManager.getNotificationEnabled()
    this.favoriteCount =
      PreferenceManager.getFavoriteIds().length

    let profile: UserProfile =
      PreferenceManager.loadUserProfile()
    this.preferenceCount = profile.preferences.length

    let userInfo: LocalUserInfo =
      PreferenceManager.loadLocalUserInfo()
    this.nickname = userInfo.nickname
    this.bio = userInfo.bio
  }

  openEditProfile(): void {
    this.editNickname = this.nickname
    this.editBio = this.bio
    this.showEditProfile = true
  }

  saveEditProfile(): void {
    let cleanNickname: string = this.editNickname.trim()
    let cleanBio: string = this.editBio.trim()

    if (cleanNickname.length === 0) {
      promptAction.showToast({ message: '昵称不能为空' })
      return
    }

    if (cleanBio.length === 0) {
      cleanBio = '让每一次比价都更聪明'
    }

    let info: LocalUserInfo = {
      nickname: cleanNickname,
      bio: cleanBio
    }

    PreferenceManager.saveLocalUserInfo(info)
    this.nickname = info.nickname
    this.bio = info.bio
    this.showEditProfile = false

    promptAction.showToast({ message: '个人资料已保存' })
  }

  @Builder SectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#7C7F87')
      .width('100%')
      .padding({ left: 18, bottom: 10 })
  }

  @Builder MenuDivider() {
    Divider()
      .strokeWidth(0.5)
      .color('#ECEEF2')
      .margin({ left: 62, right: 14 })
  }

  @Builder ProfileHome() {
    Column() {
      Scroll() {
        Column() {
          ProfileHeaderCard({
            nickname: this.nickname,
            bio: this.bio,
            preferenceCount: this.preferenceCount,
            favoriteCount: this.favoriteCount,
            onEditAction: (): void => {
              this.openEditProfile()
            }
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
              label: '个性化偏好',
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
          .border({ width: 1, color: '#ECEEF2' })

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
          .border({ width: 1, color: '#ECEEF2' })

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
            .border({ width: 1, color: '#ECEEF2' })
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

  @Builder EditProfilePanel() {
    Column() {
      Row() {
        Image($r('app.media.icon_back'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            this.showEditProfile = false
          })

        Text('编辑资料')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({ left: 12 })

        Blank()

        Text('保存')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#5267E8')
          .onClick(() => {
            this.saveEditProfile()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 18 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 10 }) {
            Column() {
              Image($r('app.media.profile_avatar'))
                .width(42)
                .height(42)
                .objectFit(ImageFit.Contain)
            }
            .width(82)
            .height(82)
            .borderRadius(26)
            .backgroundColor('#EEF1FF')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text('当前使用默认头像')
              .fontSize(12)
              .fontColor('#8E8E93')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 28, bottom: 10 })

          Column({ space: 9 }) {
            Text('昵称')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')
              .width('100%')

            TextInput({
              text: this.editNickname,
              placeholder: '请输入昵称'
            })
              .fontSize(15)
              .fontColor('#1C1C1E')
              .placeholderColor('#A0A3AA')
              .backgroundColor(Color.White)
              .border({ width: 1, color: '#ECEEF2' })
              .borderRadius(14)
              .height(52)
              .width('100%')
              .padding({ left: 16, right: 16 })
              .maxLength(20)
              .onChange((value: string) => {
                this.editNickname = value
              })
          }
          .width('100%')

          Column({ space: 9 }) {
            Text('个性签名')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')
              .width('100%')

            TextInput({
              text: this.editBio,
              placeholder: '介绍一下你的购物偏好'
            })
              .fontSize(15)
              .fontColor('#1C1C1E')
              .placeholderColor('#A0A3AA')
              .backgroundColor(Color.White)
              .border({ width: 1, color: '#ECEEF2' })
              .borderRadius(14)
              .height(52)
              .width('100%')
              .padding({ left: 16, right: 16 })
              .maxLength(40)
              .onChange((value: string) => {
                this.editBio = value
              })
          }
          .width('100%')

          Column({ space: 6 }) {
            Text('资料保存说明')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')
              .width('100%')

            Text('当前后端仅保存账号手机号与密码信息，昵称和个性签名暂按账号保存在本机。')
              .fontSize(13)
              .fontColor('#8E8E93')
              .lineHeight(20)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#EEF1FF')
          .borderRadius(14)
          .margin({ top: 4 })
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          bottom: 30
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  build() {
    Stack() {
      this.ProfileHome()

      if (this.showEditProfile) {
        this.EditProfilePanel()
      }
    }
    .width('100%')
    .height('100%')
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

    router.replaceUrl({ url: 'pages/LoginPage' })
  }
}
