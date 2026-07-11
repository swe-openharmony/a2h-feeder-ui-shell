// Entry page - redirects to FeedList (main screen)
// Waits for database initialization before navigating
import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  @StorageLink('dbReady') dbReady: boolean = false

  aboutToAppear() {
    // Wait a short time for DB init, then navigate
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/FeedList' })
    }, 500)
  }

  build() {
    Column() {
      // Splash / loading indicator while redirecting
      Column() {
        Image($r('app.media.ic_launcher'))
          .width(72)
          .height(72)
          .borderRadius(16)
          .margin({ bottom: 16 })

        Text('Feeder')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary'))

        if (!this.dbReady) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color($r('app.color.primary'))
            .margin({ top: 16 })
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#ffffff')
  }
}
