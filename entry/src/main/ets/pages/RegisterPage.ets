import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { HttpClient } from '../utils/HttpClient'
import { DataProvider } from '../data/DataProvider'

@Entry
@Component
struct RegisterPage {
  @State phone: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State isLoading: boolean = false

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Row() {
          Text('‹')
            .fontSize(34)
            .fontColor('#1C1C1E')
        }
        .width(40)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          router.back()
        })

        Text('注册账号')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')

        Blank()

        // 保持标题视觉居中
        Row()
          .width(40)
          .height(44)
      }
      .width('100%')
      .height(56)
      .padding({
        left: 8,
        right: 8
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          // 品牌区域
          Column({ space: 8 }) {

            Text('创建 ShopCompare 账号')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')

            Text('开启智能比价，收藏喜欢的商品')
              .fontSize(14)
              .fontColor('#8E8E93')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({
            top: 34,
            bottom: 30
          })

          // 注册输入区域
          Column({ space: 14 }) {
            // 手机号输入框
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

            // 设置密码
            TextInput({
              text: this.password,
              placeholder: '设置密码（6-20位）'
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

            // 确认密码
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

          // 密码状态提示
          if (this.confirmPassword.length > 0 &&
            this.password !== this.confirmPassword) {
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

          // 注册按钮
          Column() {
            Button(this.isLoading ? '注册中...' : '注册')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(
                this.canRegister() && !this.isLoading ?
                  '#1677FF' :
                  '#CDD1D8'
              )
              .borderRadius(14)
              .height(50)
              .width('100%')
              .enabled(
                this.canRegister() &&
                  !this.isLoading
              )
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

          // 登录入口
          Row({ space: 4 }) {
            Text('已有账号？')
              .fontSize(14)
              .fontColor('#8E8E93')

            Text('立即登录')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1677FF')
              .onClick(() => {
                router.back()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({
            top: 20
          })

          // 隐私政策
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

  canRegister(): boolean {
    return this.phone.length === 11 &&
      this.password.length >= 8 &&
      this.password === this.confirmPassword
  }

  async doRegister(): Promise<void> {
    this.isLoading = true

    let http: HttpClient = DataProvider.getHttpClient()

    let body: string =
      '{"phone":"' + this.phone +
        '","password":"' + this.password + '"}'

    let resp = await http.post('/auth/register', body)

    this.isLoading = false

    if (resp.statusCode === 201) {
      promptAction.showToast({
        message: '注册成功，请登录'
      })

      router.back()
    } else {
      promptAction.showToast({
        message: '注册失败，请重试'
      })
    }
  }
}