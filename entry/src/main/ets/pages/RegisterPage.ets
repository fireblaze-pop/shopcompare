import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { HttpClient } from '../utils/HttpClient'
import { DataProvider } from '../data/DataProvider'

interface RegisterResp {
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
struct RegisterPage {
  @State phone: string = ''
  @State code: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
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

  canRegister(): boolean {
    return this.phone.length === 11 &&
      this.code.length === 6 &&
      this.password.length >= 8 &&
      this.password === this.confirmPassword &&
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

  async doRegister(): Promise<void> {
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

    if (this.password.length < 8) {
      promptAction.showToast({
        message: '密码至少8位'
      })
      return
    }

    if (this.password !== this.confirmPassword) {
      promptAction.showToast({
        message: '两次输入的密码不一致'
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
      '","password":"' + this.password + '"}'

    let resp = await this.http.post(
      '/auth/register',
      body
    )

    this.isLoading = false

    if (resp.statusCode === 201) {
      try {
        let result: RegisterResp =
          JSON.parse(resp.data) as RegisterResp

        if (
          result.access_token !== undefined &&
          result.access_token !== null &&
          result.access_token.length > 0
        ) {
          this.http.setToken(result.access_token)
        }
      } catch (e) {
      }

      promptAction.showToast({
        message: '注册成功，请使用新账号登录'
      })

      router.back()
      return
    }

    promptAction.showToast({
      message: this.parseErrorMessage(
        resp.data,
        '注册失败，请重试'
      )
    })
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.icon_back'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            router.back()
          })

        Text('注册账号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({
            left: 12
          })

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({
        left: 16,
        right: 16
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          Column({ space: 8 }) {
            Column() {
              Text('比')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .width(52)
            .height(52)
            .borderRadius(16)
            .backgroundColor('#5267E8')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({
              bottom: 6
            })

            Text('创建 ShopCompare 账号')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')

            Text('验证手机号后，创建你的比价账号')
              .fontSize(14)
              .fontColor('#8E8E93')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({
            top: 32,
            bottom: 28
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

            TextInput({
              text: this.password,
              placeholder: '设置密码（至少8位）'
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

            TextInput({
              text: this.confirmPassword,
              placeholder: '再次输入密码'
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
                this.confirmPassword = value
              })
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24
          })

          if (
            this.confirmPassword.length > 0 &&
            this.password !== this.confirmPassword
          ) {
            Row() {
              Text('两次输入的密码不一致')
                .fontSize(12)
                .fontColor('#FF3B30')
            }
            .width('100%')
            .padding({
              left: 24,
              right: 24
            })
            .margin({
              top: 8
            })
          }

          Column() {
            Button(
              this.isLoading ?
                '注册中...' :
                '注册'
            )
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(
                this.canRegister() ?
                  '#5267E8' :
                  '#CDD1D8'
              )
              .borderRadius(14)
              .height(50)
              .width('100%')
              .enabled(this.canRegister())
              .onClick(() => {
                this.doRegister()
              })
          }
          .width('100%')
          .padding({
            left: 24,
            right: 24
          })
          .margin({
            top: 24
          })

          Row({ space: 4 }) {
            Text('已有账号？')
              .fontSize(14)
              .fontColor('#8E8E93')

            Text('立即登录')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#5267E8')
              .onClick(() => {
                router.back()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({
            top: 20
          })

          Text('注册即表示同意《隐私政策》')
            .fontSize(12)
            .fontColor('#9A9DA4')
            .textAlign(TextAlign.Center)
            .padding({
              left: 12,
              right: 12,
              top: 8,
              bottom: 8
            })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/PrivacyPage'
              })
            })
            .margin({
              top: 26,
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
