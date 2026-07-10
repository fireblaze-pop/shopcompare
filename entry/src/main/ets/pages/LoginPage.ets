import { NavRouter } from '../utils/NavRouter'
import { promptAction } from '@kit.ArkUI'
import { PreferenceManager } from '../utils/PreferenceManager'
import { HttpClient } from '../utils/HttpClient'
import { DataProvider } from '../data/DataProvider'

interface LoginResp {
  access_token: string
  refresh_token: string
  token_type: string
  user_id: number
}

interface SendCodeResp {
  phone: string
  code: string
  message: string
}

interface ApiErrorResp {
  detail: string
}

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State code: string = ''
  @State isPasswordMode: boolean = true
  @State isLoading: boolean = false
  @State isSendingCode: boolean = false
  @State countdown: number = 0
  @State devCodeHint: string = ''

  private timerId: number = -1
  private http: HttpClient = DataProvider.getHttpClient()

  aboutToDisappear(): void {
    this.stopCountdown()
  }

  stopCountdown(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  startCountdown(): void {
    this.stopCountdown()
    this.countdown = 60

    this.timerId = setInterval(() => {
      this.countdown = this.countdown - 1

      if (this.countdown <= 0) {
        this.countdown = 0
        this.stopCountdown()
      }
    }, 1000)
  }

  canRequestCode(): boolean {
    return this.phone.length === 11 &&
      this.countdown === 0 &&
      !this.isSendingCode &&
      !this.isLoading
  }

  parseErrorMessage(
    data: string,
    fallback: string
  ): string {
    try {
      let errorData: ApiErrorResp =
        JSON.parse(data) as ApiErrorResp

      if (
        errorData.detail !== undefined &&
        errorData.detail !== null &&
        errorData.detail.length > 0
      ) {
        return errorData.detail
      }
    } catch (e) {
    }

    return fallback
  }

  async sendCode(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({
        message: '请输入正确的手机号'
      })
      return
    }

    if (!this.canRequestCode()) {
      return
    }

    this.isSendingCode = true
    this.devCodeHint = ''

    let body: string =
      '{"phone":"' + this.phone + '"}'

    let resp = await this.http.post(
      '/auth/send-code',
      body
    )

    this.isSendingCode = false

    if (resp.statusCode !== 200) {
      promptAction.showToast({
        message: this.parseErrorMessage(
          resp.data,
          '验证码发送失败，请稍后重试'
        )
      })
      return
    }

    let message: string = '验证码已发送'

    try {
      let result: SendCodeResp =
        JSON.parse(resp.data) as SendCodeResp

      if (
        result.message !== undefined &&
        result.message !== null &&
        result.message.length > 0
      ) {
        message = result.message
      }

      if (
        result.code !== undefined &&
        result.code !== null &&
        result.code.length > 0
      ) {
        this.devCodeHint =
          '开发环境验证码：' + result.code
      }
    } catch (e) {
    }

    this.startCountdown()

    promptAction.showToast({
      message: message
    })
  }

  async handlePasswordLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({
        message: '请输入正确的手机号'
      })
      return
    }

    if (this.password.length < 8) {
      promptAction.showToast({
        message: '密码至少8位'
      })
      return
    }

    if (this.isLoading) {
      return
    }

    this.isLoading = true

    let body: string =
      '{"phone":"' + this.phone +
      '","password":"' + this.password +
      '","login_type":"password"}'

    let resp = await this.http.post(
      '/auth/login',
      body
    )

    this.isLoading = false

    if (resp.statusCode === 200) {
      this.handleLoginSuccess(resp.data)
      return
    }

    promptAction.showToast({
      message: this.parseErrorMessage(
        resp.data,
        '登录失败，请检查手机号和密码'
      )
    })

    this.password = ''
  }

  async handleCodeLogin(): Promise<void> {
    if (this.phone.length !== 11) {
      promptAction.showToast({
        message: '请输入正确的手机号'
      })
      return
    }

    if (this.code.length !== 6) {
      promptAction.showToast({
        message: '请输入6位验证码'
      })
      return
    }

    if (this.isLoading) {
      return
    }

    this.isLoading = true

    let body: string =
      '{"phone":"' + this.phone +
      '","code":"' + this.code +
      '","login_type":"code"}'

    let resp = await this.http.post(
      '/auth/login',
      body
    )

    this.isLoading = false

    if (resp.statusCode === 200) {
      this.handleLoginSuccess(resp.data)
      return
    }

    promptAction.showToast({
      message: this.parseErrorMessage(
        resp.data,
        '验证码错误或已过期'
      )
    })

    this.code = ''
  }

  handleLoginSuccess(data: string): void {
    try {
      let result: LoginResp =
        JSON.parse(data) as LoginResp

      if (
        result.access_token === undefined ||
        result.access_token === null ||
        result.access_token.length === 0
      ) {
        promptAction.showToast({
          message: '登录响应缺少访问令牌'
        })
        return
      }

      this.http.setToken(result.access_token)
      PreferenceManager.setCurrentUserId(
        result.user_id.toString()
      )

      promptAction.showToast({
        message: '登录成功'
      })

      this.navigateAfterLogin()
    } catch (e) {
      promptAction.showToast({
        message: '登录响应解析失败'
      })
    }
  }

  navigateAfterLogin(): void {
    let firstLaunch: boolean =
      PreferenceManager.isFirstLaunch()

    if (firstLaunch) {
      NavRouter.push('QuestionnairePage')
    } else {
      NavRouter.replace('HomePage')
    }
  }

  goRegister(): void {
    NavRouter.push('RegisterPage')
  }

  build() {
    Column() {
      Scroll() {
        Column() {
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
            .backgroundColor('#5267E8')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({
              bottom: 8
            })

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

          Column({ space: 14 }) {
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
                  this.devCodeHint = ''
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
              TextInput({
                text: this.password,
                placeholder: '请输入密码（至少8位）'
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
              Row() {
                TextInput({
                  text: this.code,
                  placeholder: '请输入6位验证码'
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
                  this.isSendingCode ?
                    '发送中...' :
                    (
                      this.countdown > 0 ?
                        this.countdown.toString() + 's后重试' :
                        '获取验证码'
                    )
                )
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(
                    this.canRequestCode() ?
                      '#5267E8' :
                      '#AEAEB2'
                  )
                  .margin({
                    right: 16
                  })
                  .onClick(() => {
                    if (this.canRequestCode()) {
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

              if (this.devCodeHint.length > 0) {
                Text(this.devCodeHint)
                  .fontSize(12)
                  .fontColor('#5267E8')
                  .width('100%')
              }
            }
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24
          })

          Column() {
            Button(
              this.isLoading ?
                (
                  this.isPasswordMode ?
                    '登录中...' :
                    '验证中...'
                ) :
                '登录'
            )
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(
                this.isLoading ?
                  '#AEB7F2' :
                  '#5267E8'
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

          Row({ space: 4 }) {
            Text('还没有账号？')
              .fontSize(14)
              .fontColor('#8E8E93')

            Text('立即注册')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#5267E8')
              .onClick(() => {
                this.goRegister()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({
            top: 18
          })

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

          Text('登录即表示同意《隐私政策》')
            .fontSize(12)
            .fontColor('#9A9DA4')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              NavRouter.push('PrivacyPage')
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
