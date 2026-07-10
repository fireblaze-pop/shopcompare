import { router } from '@kit.ArkUI'

export class NavRouter {
  static navPathStack: NavPathStack = new NavPathStack()

  static push(pageName: string, param?: Object): void {
    NavRouter.navPathStack.pushDestination({ name: pageName, param: param })
  }

  static replace(pageName: string, param?: Object): void {
    NavRouter.navPathStack.clear()
    NavRouter.navPathStack.pushDestination({ name: pageName, param: param })
  }

  static back(): void {
    NavRouter.navPathStack.pop()
  }

  static popToRoot(): void {
    NavRouter.navPathStack.clear()
  }
}
