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
      Row() {
        Text('\u2190')
          .fontSize(24)
          .fontColor('#1C1C1E')
          .padding({ right: 12 })
          .onClick(() => {
            router.back()
          })
        Text('注册')
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#1C1C1E')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Column() {
        TextInput({ placeholder: '请输入手机号', text: $$this.phone })
          .type(InputType.Number)
          .maxLength(11)
          .fontSize(15)
          .backgroundColor('#F2F2F7')
          .borderRadius(12)
          .height(48)
          .width('100%')
          .margin({ top: 40, left: 20, right: 20 })
          .onChange((value: string) => {
            this.phone = value
          })

        TextInput({ placeholder: '设置密码（6-20位）', text: $$this.password })
          .type(InputType.Password)
          .maxLength(20)
          .fontSize(15)
          .backgroundColor('#F2F2F7')
          .borderRadius(12)
          .height(48)
          .width('100%')
          .margin({ top: 16, left: 20, right: 20 })
          .onChange((value: string) => {
            this.password = value
          })

        TextInput({ placeholder: '确认密码', text: $$this.confirmPassword })
          .type(InputType.Password)
          .maxLength(20)
          .fontSize(15)
          .backgroundColor('#F2F2F7')
          .borderRadius(12)
          .height(48)
          .width('100%')
          .margin({ top: 16, left: 20, right: 20 })
          .onChange((value: string) => {
            this.confirmPassword = value
          })

        Button(this.isLoading ? '注册中...' : '注册')
          .fontSize(16)
          .fontWeight(600)
          .fontColor(Color.White)
          .backgroundColor(this.canRegister() && !this.isLoading ? '#007AFF' : '#8E8E93')
          .borderRadius(22)
          .height(48)
          .width('100%')
          .margin({ top: 30, left: 20, right: 20 })
          .enabled(this.canRegister() && !this.isLoading)
          .onClick(() => {
            this.doRegister()
          })

        Text('已有账号？立即登录')
          .fontSize(14)
          .fontColor('#007AFF')
          .margin({ top: 20 })
          .onClick(() => {
            router.back()
          })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F2F2F7')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  canRegister(): boolean {
    return this.phone.length === 11 && this.password.length >= 6 &&
      this.password === this.confirmPassword
  }

  async doRegister(): Promise<void> {
    this.isLoading = true
    let http: HttpClient = DataProvider.getHttpClient()
    let body: string = '{"phone":"' + this.phone + '","password":"' + this.password + '"}'
    let resp = await http.post('/auth/register', body)
    this.isLoading = false

    if (resp.statusCode === 201) {
      promptAction.showToast({ message: '注册成功，请登录' })
      router.back()
    } else {
      promptAction.showToast({ message: '注册失败，请重试' })
    }
  }
}
