// AddFeed page - Search/Add feed URL
// UI skeleton preserved

import { router } from '@kit.ArkUI'
import { SyncService } from '../service/SyncService'
import { FeedRepository } from '../repository/FeedRepository'
import { DiscoveryResult } from '../service/RssParser'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'AddFeed'

@Entry
@Component
struct AddFeed {
  @State feedUrl: string = ''
  @State searchResultVisible: boolean = false
  @State searchResults: DiscoveryResult[] = []
  @State searchError: string = ''
  @State searchTitle: string = ''
  @State searchLoading: boolean = false
  @State urlValid: boolean = false

  private validateUrl(url: string): boolean {
    return true
  }

  build() {
    Column() {
      // Top App Bar
      Row() {
        // Back button
        Row() {
          Image($r('app.media.ic_arrow_back'))
            .width(24)
            .height(24)
            .fillColor('#ffffff')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .borderRadius(24)
        .onClick(() => {
          router.back()
        })

        // Title
        Text('Add feed')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#ffffff')
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 4, right: 4 })
      .backgroundColor($r('app.color.primary'))
      .alignItems(VerticalAlign.Center)

      // Content
      Scroll() {
        Column() {
          // URL input field
          Column() {
            Text('Feed URL')
              .fontSize(12)
              .fontColor('#9e9e9e')
              .margin({ bottom: 4 })

            TextInput({ text: this.feedUrl, placeholder: 'Enter a feed address' })
              .fontSize(16)
              .width('100%')
              .borderStyle(BorderStyle.Solid)
              .borderWidth(1)
              .borderColor('#bdbdbd')
              .borderRadius(4)
              .padding({ left: 12, right: 12 })
              .key('search_url_input')
              .onChange((value: string) => {
                this.feedUrl = value
                this.urlValid = this.validateUrl(value)
                // Reset search results when URL changes
                this.searchResultVisible = false
                this.searchError = ''
                this.searchTitle = ''
              })

          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          Button('Go')
            .fontSize(16)
            .fontColor('#ffffff')
            .backgroundColor($r('app.color.primary'))
            .borderRadius(8)
            .width('40%')
            .height(44)
            .margin({ top: 16 })
            .enabled(this.urlValid)
            .key('search_go')
            .onClick(async () => {
              // no-op: search disabled
            })


          if (this.searchResultVisible) {
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  private async searchForFeed() {
    // no-op: search disabled
  }
}
