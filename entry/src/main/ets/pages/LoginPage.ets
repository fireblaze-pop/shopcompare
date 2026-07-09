import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { PreferenceManager } from '../utils/PreferenceManager'
import { HttpClient } from '../utils/HttpClient'
import { DataProvider } from '../data/DataProvider'

interface LoginResp {
  access_token: string
  user_id: number
}

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State code: string = ''
  @State isPasswordMode: boolean = true
  @State isLoading: boolean = false
  @State countdown: number = 0
  @State canSendCode: boolean = false

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
      promptAction.showToast({
        message: '请输入正确的手机号'
      })
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
      promptAction.showToast({
        message: '请输入正确的手机号'
      })
      return
    }

    if (this.password.length < 6) {
      promptAction.showToast({
        message: '密码至少6位'
      })
      return
    }

    this.isLoading = true

    let body: string =
      '{"phone":"' + this.phone +
        '","password":"' + this.password + '"}'

    let resp = await this.http.post('/auth/login', body)

    this.isLoading = false

    if (resp.statusCode === 200) {
      let result: LoginResp =
        JSON.parse(resp.data) as LoginResp

      this.http.setToken(result.access_token)
      PreferenceManager.setCurrentUserId(result.user_id.toString())

      this.navigateAfterLogin()
    } else {
      promptAction.showToast({
        message: '登录失败：手机号或密码错误'
      })

      this.password = ''
    }
  }

  async handleCodeLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({
        message: '请输入正确的手机号'
      })
      return
    }

    if (this.code.length < 6) {
      promptAction.showToast({
        message: '请输入6位验证码'
      })
      return
    }

    this.isLoading = true

    let body: string =
      '{"phone":"' + this.phone +
        '","code":"' + this.code +
        '","login_type":"code"}'

    let resp = await this.http.post('/auth/login', body)

    this.isLoading = false

    if (resp.statusCode === 200) {
      let result: LoginResp =
        JSON.parse(resp.data) as LoginResp

      this.http.setToken(result.access_token)
      PreferenceManager.setCurrentUserId(result.user_id.toString())

      this.navigateAfterLogin()
    } else {
      promptAction.showToast({
        message: '验证码错误或已过期'
      })

      this.code = ''
    }
  }

  navigateAfterLogin(): void {
    let firstLaunch: boolean =
      PreferenceManager.isFirstLaunch()

    if (firstLaunch) {
      router.pushUrl({
        url: 'pages/QuestionnairePage'
      })
    } else {
      router.replaceUrl({
        url: 'pages/HomePage'
      })
    }
  }

  goRegister(): void {
    router.pushUrl({
      url: 'pages/RegisterPage'
    })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 品牌区域
          Column({ space: 8 }) {
            Column() {
              Text('比')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .width(56)
            .height(56)
            .borderRadius(16)
            .backgroundColor('#1677FF')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 8 })

            Text('欢迎使用 ShopCompare')
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')

            Text('登录后同步收藏、偏好与价格提醒')
              .fontSize(14)
              .fontColor('#8E8E93')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({
            top: 52,
            bottom: 28
          })

          // 登录方式切换
          Column() {
            Row() {
              Row() {
                Text('密码登录')
                  .fontSize(14)
                  .fontWeight(
                    this.isPasswordMode ?
                      FontWeight.Medium :
                      FontWeight.Normal
                  )
                  .fontColor(
                    this.isPasswordMode ?
                      '#1C1C1E' :
                      '#8E8E93'
                  )
              }
              .layoutWeight(1)
              .height(40)
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .backgroundColor(
                this.isPasswordMode ?
                  Color.White :
                  Color.Transparent
              )
              .borderRadius(10)
              .onClick(() => {
                this.isPasswordMode = true
              })

              Row() {
                Text('验证码登录')
                  .fontSize(14)
                  .fontWeight(
                    !this.isPasswordMode ?
                      FontWeight.Medium :
                      FontWeight.Normal
                  )
                  .fontColor(
                    !this.isPasswordMode ?
                      '#1C1C1E' :
                      '#8E8E93'
                  )
              }
              .layoutWeight(1)
              .height(40)
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .backgroundColor(
                !this.isPasswordMode ?
                  Color.White :
                  Color.Transparent
              )
              .borderRadius(10)
              .onClick(() => {
                this.isPasswordMode = false
              })
            }
            .width('100%')
            .height(44)
            .padding(2)
            .backgroundColor('#ECEFF4')
            .borderRadius(12)
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24
          })
          .margin({
            bottom: 20
          })

          // 输入区域
          Column({ space: 14 }) {
            // 手机号
            Row() {
              Text('+86')
                .fontSize(15)
                .fontColor('#1C1C1E')
                .margin({
                  left: 16,
                  right: 14
                })

              Column()
                .width(1)
                .height(22)
                .backgroundColor('#E0E2E7')

              TextInput({
                text: this.phone,
                placeholder: '请输入手机号'
              })
                .type(InputType.Number)
                .maxLength(11)
                .fontSize(15)
                .fontColor('#1C1C1E')
                .placeholderColor('#A0A3AA')
                .backgroundColor(Color.Transparent)
                .border({
                  width: 0
                })
                .layoutWeight(1)
                .height(52)
                .padding({
                  left: 14,
                  right: 16
                })
                .onChange((value: string) => {
                  this.phone = value
                  this.canSendCode =
                    value.length === 11 &&
                      this.countdown === 0
                })
            }
            .width('100%')
            .height(52)
            .backgroundColor(Color.White)
            .border({
              width: 1,
              color: '#E6E8EE'
            })
            .borderRadius(14)
            .alignItems(VerticalAlign.Center)

            if (this.isPasswordMode) {
              // 密码
              TextInput({
                text: this.password,
                placeholder: '请输入密码（6-20位）'
              })
                .type(InputType.Password)
                .maxLength(20)
                .fontSize(15)
                .fontColor('#1C1C1E')
                .placeholderColor('#A0A3AA')
                .backgroundColor(Color.White)
                .border({
                  width: 1,
                  color: '#E6E8EE'
                })
                .borderRadius(14)
                .height(52)
                .width('100%')
                .padding({
                  left: 16,
                  right: 12
                })
                .onChange((value: string) => {
                  this.password = value
                })
            } else {
              // 验证码
              Row() {
                TextInput({
                  text: this.code,
                  placeholder: '请输入验证码'
                })
                  .type(InputType.Number)
                  .maxLength(6)
                  .fontSize(15)
                  .fontColor('#1C1C1E')
                  .placeholderColor('#A0A3AA')
                  .backgroundColor(Color.Transparent)
                  .border({
                    width: 0
                  })
                  .layoutWeight(1)
                  .height(52)
                  .padding({
                    left: 16,
                    right: 8
                  })
                  .onChange((value: string) => {
                    this.code = value
                  })

                Text(
                  this.countdown > 0 ?
                    this.countdown.toString() + 's后重试' :
                    '获取验证码'
                )
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(
                    this.canSendCode ?
                      '#1677FF' :
                      '#AEAEB2'
                  )
                  .margin({
                    right: 16
                  })
                  .onClick(() => {
                    if (this.canSendCode) {
                      this.sendCode()
                    }
                  })
              }
              .width('100%')
              .height(52)
              .backgroundColor(Color.White)
              .border({
                width: 1,
                color: '#E6E8EE'
              })
              .borderRadius(14)
              .alignItems(VerticalAlign.Center)
            }
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24
          })

          // 主登录按钮
          Column() {
            Button(
              this.isLoading ?
                (this.isPasswordMode ? '登录中...' : '验证中...') :
                '登录'
            )
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(
                this.isLoading ?
                  '#AFCBFF' :
                  '#1677FF'
              )
              .borderRadius(14)
              .height(50)
              .width('100%')
              .enabled(!this.isLoading)
              .onClick(() => {
                if (this.isPasswordMode) {
                  this.handlePasswordLogin()
                } else {
                  this.handleCodeLogin()
                }
              })
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24
          })
          .margin({
            top: 22
          })

          // 注册入口
          Row({ space: 4 }) {
            Text('还没有账号？')
              .fontSize(14)
              .fontColor('#8E8E93')

            Text('立即注册')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1677FF')
              .onClick(() => {
                this.goRegister()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({
            top: 18
          })

          // 跳过登录
          Text('暂不登录，先逛逛')
            .fontSize(14)
            .fontColor('#62656C')
            .padding({
              left: 16,
              right: 16,
              top: 8,
              bottom: 8
            })
            .onClick(() => {
              this.navigateAfterLogin()
            })
            .margin({
              top: 8
            })

          // 隐私政策
          Text('登录即表示同意《隐私政策》')
            .fontSize(12)
            .fontColor('#9A9DA4')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/PrivacyPage'
              })
            })
            .margin({
              top: 30,
              bottom: 40
            })
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
    .backgroundColor('#F7F8FA')
  }
}