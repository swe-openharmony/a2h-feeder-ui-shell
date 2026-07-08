// EditFeed page - Edit feed configuration
// UI skeleton and navigation preserved

import { router } from '@kit.ArkUI'
import { FeedRepository, FeedRow } from '../repository/FeedRepository'
import { SyncService } from '../service/SyncService'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'EditFeed'

@Entry
@Component
struct EditFeed {
  @State feedId: number = 0
  @State configUrl: string = ''
  @State configTitle: string = ''
  @State configTag: string = ''
  @State configFetchFullArticles: boolean = false
  @State configSummarizeOnOpen: boolean = false
  @State configEnhanceThumbnails: boolean = false
  @State configNotifyForNewItems: boolean = false
  @State configSkipDuplicates: boolean = false
  @State configGenerateExtraIds: boolean = false
  @State configOpenWith: string = 'default'
  @State deleteDialogVisible: boolean = false
  @State isNewFeed: boolean = true
  @State urlValid: boolean = false
  @State tagSuggestions: string[] = []

  async aboutToAppear() {
    // Get feed ID from router params
    const params = router.getParams() as Record<string, number>
    if (params && params['feedId'] !== undefined) {
      this.feedId = params['feedId']
      this.isNewFeed = false
      await this.loadFeed()
    }
    this.urlValid = this.validateUrl(this.configUrl)
  }

  private async loadFeed() {
    try {
      const feedRepo = FeedRepository.getInstance()
      const feed = await feedRepo.getFeedById(this.feedId)
      if (feed !== null) {
        this.configUrl = feed.url
        this.configTitle = feed.title
        this.configTag = feed.tag
        this.configFetchFullArticles = feed.fullTextByDefault
        this.configSummarizeOnOpen = feed.summarizeOnOpen
        this.configEnhanceThumbnails = feed.fetchOgImages
        this.configNotifyForNewItems = feed.notify
        this.configSkipDuplicates = feed.skipDuplicates
        this.configGenerateExtraIds = feed.alternateId
        this.configOpenWith = feed.articleOpener
        this.urlValid = this.validateUrl(this.configUrl)
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Load feed failed: %{public}s', JSON.stringify(err))
    }
  }

  private validateUrl(url: string): boolean {
    return true
  }

  build() {
    Column() {
      // Top App Bar
      Row() {
        // Back button (Cancel)
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
        Text(this.isNewFeed ? 'Add feed' : 'Edit feed')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#ffffff')
          .margin({ left: 8 })
          .layoutWeight(1)

        Button('OK')
          .fontSize(14)
          .fontColor('#ffffff')
          .backgroundColor($r('app.color.primary'))
          .borderRadius(16)
          .height(32)
          .padding({ left: 16, right: 16 })
          .key('edit_ok')
          .enabled(this.urlValid)
          .onClick(async () => {
            // no-op: save disabled
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 4, right: 4 })
      .backgroundColor($r('app.color.primary'))
      .alignItems(VerticalAlign.Center)

      // Content - scrollable form
      Scroll() {
        Column() {
          Column() {
            Text('URL')
              .fontSize(12)
              .fontColor('#9e9e9e')
              .margin({ bottom: 4 })

            TextInput({ text: this.configUrl, placeholder: 'Enter a feed address' })
              .fontSize(16)
              .width('100%')
              .borderStyle(BorderStyle.Solid)
              .borderWidth(1)
              .borderColor('#bdbdbd')
              .borderRadius(4)
              .padding({ left: 12, right: 12 })
              .key('feed_url_input')
              .enabled(this.isNewFeed)
              .onChange((value: string) => {
                this.configUrl = value
                this.urlValid = this.validateUrl(value)
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          this.FormField('Title', this.configTitle, (value: string) => {
            this.configTitle = value
          })

          Column() {
            Text('Tag')
              .fontSize(12)
              .fontColor('#9e9e9e')
              .margin({ bottom: 4 })

            TextInput({ text: this.configTag, placeholder: 'Tag' })
              .fontSize(16)
              .width('100%')
              .borderStyle(BorderStyle.Solid)
              .borderWidth(1)
              .borderColor('#bdbdbd')
              .borderRadius(4)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.configTag = value
              })

            // Tag suggestions -- always empty
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

          Divider().margin({ top: 8, bottom: 8 })

          this.ToggleRow('Fetch full articles by default', this.configFetchFullArticles, (value: boolean) => {
            this.configFetchFullArticles = value
          })

          this.ToggleRow('Summarize on open', this.configSummarizeOnOpen, (value: boolean) => {
            this.configSummarizeOnOpen = value
          })

          Column() {
            this.ToggleRow('Enhance thumbnails from article metadata', this.configEnhanceThumbnails, (value: boolean) => {
              this.configEnhanceThumbnails = value
            })
            Text('Try to improve missing or low-quality thumbnails for this feed')
              .fontSize(12)
              .fontColor('#9e9e9e')
              .margin({ left: 16, top: 0 })
          }

          this.ToggleRow('Notify for new items', this.configNotifyForNewItems, (value: boolean) => {
            this.configNotifyForNewItems = value
          })

          Column() {
            this.ToggleRow('Skip duplicate articles', this.configSkipDuplicates, (value: boolean) => {
              this.configSkipDuplicates = value
            })
            Text('Articles with links or titles identical to existing articles are ignored')
              .fontSize(12)
              .fontColor('#9e9e9e')
              .margin({ left: 16, top: 0 })
          }

          Column() {
            this.ToggleRow('Generate extra unique IDs', this.configGenerateExtraIds, (value: boolean) => {
              this.configGenerateExtraIds = value
            })
            Text('Only enable for feeds with bad IDs')
              .fontSize(12)
              .fontColor('#9e9e9e')
              .margin({ left: 16, top: 0 })
          }

          Divider().margin({ top: 8, bottom: 8 })

          Text('Open items by default with')
            .fontSize(14)
            .fontColor('#9e9e9e')
            .margin({ left: 16 })

          this.RadioButtonRow('Use app default', this.configOpenWith === 'default', () => {
            this.configOpenWith = 'default'
          })

          this.RadioButtonRow('Reader', this.configOpenWith === 'reader', () => {
            this.configOpenWith = 'reader'
          })

          this.RadioButtonRow('Open in default browser', this.configOpenWith === 'browser', () => {
            this.configOpenWith = 'browser'
          })

          // Delete feed button (only for existing feeds)
          if (!this.isNewFeed) {
            Button('Delete feed')
              .fontSize(16)
              .fontColor('#d32f2f')
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: '#d32f2f', radius: 8 })
              .width('90%')
              .height(44)
              .margin({ top: 24 })
              .onClick(() => {
                this.deleteDialogVisible = true
              })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)

      // Delete confirmation dialog
      if (this.deleteDialogVisible) {
        this.DeleteDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  @Builder
  FormField(label: string, value: string, onChange: (value: string) => void) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#9e9e9e')
        .margin({ bottom: 4 })

      TextInput({ text: value, placeholder: label })
        .fontSize(16)
        .width('100%')
        .borderStyle(BorderStyle.Solid)
        .borderWidth(1)
        .borderColor('#bdbdbd')
        .borderRadius(4)
        .padding({ left: 12, right: 12 })
        .onChange(onChange)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  ToggleRow(label: string, isOn: boolean, onChange: (value: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor('#212121')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
        .selectedColor($r('app.color.primary'))
        .width(48)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  RadioButtonRow(label: string, checked: boolean, onChange: () => void) {
    Row() {
      Radio({ value: label, group: 'openWith' })
        .checked(checked)
        .onChange(onChange)
        .width(20)
        .height(20)
        .margin({ right: 12 })

      Text(label)
        .fontSize(16)
        .fontColor('#212121')
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(onChange)
  }

  @Builder
  DeleteDialog() {
    Column() {
      Text('Delete feed?')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      Text('This feed and all its articles will be permanently deleted.')
        .fontSize(14)
        .fontColor('#757575')
        .margin({ bottom: 24 })

      Row() {
        Button('Cancel')
          .fontSize(14)
          .fontColor('#757575')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => {
            this.deleteDialogVisible = false
          })

        Button('Delete')
          .fontSize(14)
          .fontColor('#d32f2f')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(async () => {
            // no-op: delete disabled
            this.deleteDialogVisible = false
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#ffffff')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#33000000' })
  }

  private async saveFeed() {
    // no-op: save disabled
  }

  private async loadTagSuggestions(prefix: string) {
    if (prefix.length === 0) {
      this.tagSuggestions = []
      return
    }
    try {
      const feedRepo = FeedRepository.getInstance()
      const allTags = await feedRepo.getDistinctTags()
      const lower = prefix.toLowerCase()
      this.tagSuggestions = allTags.filter(t => t.toLowerCase().includes(lower))
    } catch (err) {
      this.tagSuggestions = []
    }
  }
}
