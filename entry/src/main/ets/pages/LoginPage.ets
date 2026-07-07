import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { PreferenceManager } from '../utils/PreferenceManager'
import { HttpClient } from '../utils/HttpClient'
import { DataProvider } from '../data/DataProvider'

interface LoginResp {
  access_token: string
  user_id: string
}

@Entry
@Component
struct LoginPage {
  @State phone: string = '13800000000'
  @State password: string = 'test123456'
  @State code: string = ''
  @State isPasswordMode: boolean = true
  @State isLoading: boolean = false
  @State countdown: number = 0
  @State canSendCode: boolean = true
  private timerId: number = -1
  private http: HttpClient = DataProvider.getHttpClient()

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  sendCode(): void {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' })
      return
    }
    this.countdown = 60
    this.canSendCode = false
    this.timerId = setInterval(() => {
      this.countdown = this.countdown - 1
      if (this.countdown <= 0) {
        clearInterval(this.timerId)
        this.timerId = -1
        this.countdown = 0
        this.canSendCode = true
      }
    }, 1000)
  }

  async handlePasswordLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号' })
      return
    }
    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码至少6位' })
      return
    }
    this.isLoading = true

    let body: string = '{"phone":"' + this.phone + '","password":"' + this.password + '"}'
    let resp = await this.http.post('/auth/login', body)
    this.isLoading = false

    if (resp.statusCode === 200) {
      let result: LoginResp = JSON.parse(resp.data) as LoginResp
      this.http.setToken(result.access_token)
      PreferenceManager.setCurrentUserId(result.user_id)
      this.navigateAfterLogin()
    } else {
      promptAction.showToast({ message: '登录失败：手机号或密码错误' })
      this.password = ''
    }
  }

  async handleCodeLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      return
    }
    if (this.code.length < 6) {
      return
    }
    this.isLoading = true

    let body: string = '{"phone":"' + this.phone + '","code":"' + this.code + '"}'
    let resp = await this.http.post('/auth/login-code', body)
    this.isLoading = false

    if (resp.statusCode === 200) {
      let result: LoginResp = JSON.parse(resp.data) as LoginResp
      this.http.setToken(result.access_token)
      PreferenceManager.setCurrentUserId(result.user_id)
      this.navigateAfterLogin()
    } else {
      promptAction.showToast({ message: '验证码错误或已过期' })
      this.code = ''
    }
  }

  navigateAfterLogin(): void {
    let firstLaunch: boolean = PreferenceManager.isFirstLaunch()
    if (firstLaunch) {
      router.pushUrl({ url: 'pages/QuestionnairePage' })
    } else {
      router.replaceUrl({ url: 'pages/HomePage' })
    }
  }

  goRegister(): void {
    router.pushUrl({ url: 'pages/RegisterPage' })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Text('欢迎使用')
            .fontSize(28)
            .fontWeight(700)
            .fontColor('#1C1C1E')
            .margin({ top: 60, bottom: 8 })

          Text('登录后开启智能比价体验')
            .fontSize(15)
            .fontColor('#8E8E93')
            .margin({ bottom: 40 })

          Row() {
            Text('+86')
              .fontSize(15)
              .fontColor('#1C1C1E')
              .margin({ left: 16, right: 12 })

            Column()
              .width(1)
              .height(24)
              .backgroundColor('#D1D1D6')

            TextInput({ placeholder: '请输入手机号' })
              .type(InputType.Number)
              .maxLength(11)
              .fontSize(15)
              .backgroundColor(Color.Transparent)
              .layoutWeight(1)
              .margin({ left: 12, right: 16 })
              .onChange((value: string) => {
                this.phone = value
                this.canSendCode = value.length === 11 && this.countdown === 0
              })
          }
          .width('100%')
          .height(48)
          .backgroundColor('#F2F2F7')
          .borderRadius(12)
          .margin({ left: 20, right: 20 })

          if (this.isPasswordMode) {
            TextInput({ placeholder: '请输入密码（6-20位）' })
              .type(InputType.Password)
              .maxLength(20)
              .fontSize(15)
              .backgroundColor('#F2F2F7')
              .borderRadius(12)
              .height(48)
              .width('100%')
              .margin({ left: 20, right: 20, top: 16 })
              .onChange((value: string) => {
                this.password = value
              })
          } else {
            Button(this.countdown > 0 ?
              '重新发送(' + this.countdown.toString() + 's)' : '获取验证码')
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor(this.canSendCode ? '#007AFF' : '#8E8E93')
              .borderRadius(22)
              .height(44)
              .width('100%')
              .margin({ left: 20, right: 20, top: 16 })
              .enabled(this.canSendCode)
              .onClick(() => {
                this.sendCode()
              })

            TextInput({ placeholder: '请输入验证码' })
              .type(InputType.Number)
              .maxLength(6)
              .fontSize(15)
              .backgroundColor('#F2F2F7')
              .borderRadius(12)
              .height(48)
              .width('100%')
              .margin({ left: 20, right: 20, top: 16 })
              .onChange((value: string) => {
                this.code = value
              })
          }

          if (this.isPasswordMode) {
            Button(this.isLoading ? '登录中...' : '登录')
              .fontSize(16)
              .fontWeight(600)
              .fontColor(Color.White)
              .backgroundColor(!this.isLoading ? '#007AFF' : '#8E8E93')
              .borderRadius(22)
              .height(48)
              .width('100%')
              .margin({ left: 20, right: 20, top: 24 })
              .enabled(!this.isLoading)
              .onClick(() => {
                this.handlePasswordLogin()
              })
          } else {
            Button(this.isLoading ? '验证中...' : '登录')
              .fontSize(16)
              .fontWeight(600)
              .fontColor(Color.White)
              .backgroundColor(!this.isLoading ? '#007AFF' : '#8E8E93')
              .borderRadius(22)
              .height(48)
              .width('100%')
              .margin({ left: 20, right: 20, top: 24 })
              .enabled(!this.isLoading)
              .onClick(() => {
                this.handleCodeLogin()
              })
          }

          Row() {
            if (this.isPasswordMode) {
              Text('使用验证码登录')
                .fontSize(14)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.isPasswordMode = false
                })
            } else {
              Text('使用密码登录')
                .fontSize(14)
                .fontColor('#007AFF')
                .onClick(() => {
                  this.isPasswordMode = true
                })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 12 })

          Row() {
            Divider()
              .layoutWeight(1)
              .color('#D1D1D6')

            Text('快速操作')
              .fontSize(12)
              .fontColor('#8E8E93')
              .margin({ left: 12, right: 12 })

            Divider()
              .layoutWeight(1)
              .color('#D1D1D6')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ left: 20, right: 20, top: 32, bottom: 24 })

          Row() {
            Button('注册')
              .fontSize(16)
              .fontWeight(600)
              .fontColor(Color.White)
              .backgroundColor('#007AFF')
              .borderRadius(22)
              .height(48)
              .layoutWeight(1)
              .margin({ right: 12 })
              .onClick(() => {
                this.goRegister()
              })

            Button('跳过登录')
              .fontSize(16)
              .fontColor('#007AFF')
              .backgroundColor('#FFFFFF')
              .borderRadius(22)
              .borderWidth(1)
              .borderColor('#007AFF')
              .height(48)
              .layoutWeight(1)
              .onClick(() => {
                this.navigateAfterLogin()
              })
          }
          .width('100%')
          .margin({ left: 20, right: 20, bottom: 20 })

          Text('登录即表示同意《隐私政策》')
            .fontSize(12)
            .fontColor('#8E8E93')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              router.pushUrl({ url: 'pages/PrivacyPage' })
            })
            .margin({ bottom: 40 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}
