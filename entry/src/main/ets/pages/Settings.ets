// Settings page - App settings
// UI skeleton, navigation, and toggle rendering preserved

import { router } from '@kit.ArkUI'
import { SettingsRepository } from '../repository/SettingsRepository'
import { BlocklistRepository, BlocklistEntry } from '../repository/BlocklistRepository'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'Settings'

@Entry
@Component
struct Settings {
  // Sync settings
  @StorageLink('sync_frequency') syncFrequency: string = 'Manually'
  @StorageLink('sync_on_wifi_only') syncOnWifi: boolean = false
  @StorageLink('sync_on_charging_only') syncOnCharging: boolean = false
  @StorageLink('sync_on_startup') syncOnStartup: boolean = false
  @StorageLink('max_feed_items') maxFeedItems: number = 100

  // Display settings
  @StorageLink('theme') theme: string = 'Day'
  @StorageLink('dark_theme_preference') darkPreference: string = 'Dark'
  @StorageLink('show_thumbnails') showThumbnails: boolean = true
  @StorageLink('sort_order') sortOrder: string = 'Newest first'
  @StorageLink('swipe_to_mark_read') swipeMarkRead: string = 'Only from end'
  @StorageLink('mark_as_read_on_scroll') markReadOnScroll: boolean = false
  @StorageLink('show_fab') showFab: boolean = true
  @StorageLink('open_drawer_on_fab') openDrawerOnFab: boolean = false
  @StorageLink('feed_item_style') feedItemStyle: string = 'Card'
  @StorageLink('max_lines') maxLines: number = 2
  @StorageLink('show_only_title') showOnlyTitle: boolean = false
  @StorageLink('show_reading_time') showReadingTime: boolean = false
  @StorageLink('show_title_unread_count') showTitleUnreadCount: boolean = false

  // Article settings
  @StorageLink('open_item_with') openItemWith: string = 'Reader'
  @StorageLink('open_link_with') openLinkWith: string = 'Custom tab'
  @StorageLink('open_browser_split_screen') openBrowserSplit: boolean = false
  @StorageLink('paging_mode') pagingMode: boolean = false
  @StorageLink('animated_paging') animatedPaging: boolean = false
  @StorageLink('image_wifi_only') imageWifiOnly: boolean = false

  // Block list
  @StorageLink('block_list_apply_summaries') blockListApplySummaries: boolean = false

  // TTS
  @StorageLink('tts_detect_language') detectLanguage: boolean = true

  // Translation
  @StorageLink('translate_feed_cards') translateFeedCards: boolean = false
  @StorageLink('translate_articles') translateArticles: boolean = false

  // Notify
  @StorageLink('notify_new_items') notifyNewItems: boolean = false

  @State selectVisible: boolean = false
  @State selectKey: string = ''
  @State selectOptions: string[] = []
  @State selectTitle: string = ''
  @State blockListDialogVisible: boolean = false
  @State blockListPatterns: BlocklistEntry[] = []
  @State newBlockPattern: string = ''

  aboutToAppear() {
    // Settings are already loaded to AppStorage by SettingsRepository.loadAllToAppStorage()
  }

  build() {
    Column() {
      // Top App Bar
      Row() {
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

        Text('Settings')
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

      // Settings content
      Scroll() {
        Column() {
          // === Display section (matching Android order) ===
          this.SectionHeader('Display')

          this.SelectRow('Theme', this.theme,
            ['Day', 'Night', 'System', 'E-Ink'],
            'theme')

          this.ToggleSettingRow('Open links in app', this.openItemWith !== 'Reader', (v) => {
            SettingsRepository.getInstance().putString('open_item_with', v ? 'Custom Tab' : 'Reader')
          })

          this.ToggleSettingRow('Notify for new items', this.notifyNewItems, (v) => {
            SettingsRepository.getInstance().putBoolean('notify_new_items', v)
          })

          this.SelectRow('Sync interval', this.syncFrequency,
            ['Manual', '15 min', '30 min', '1 hour', '3 hours', '6 hours', '12 hours', '24 hours'],
            'sync_frequency')

          this.ToggleSettingRow('Only on WiFi', this.syncOnWifi, (v) => {
            SettingsRepository.getInstance().putBoolean('sync_on_wifi_only', v)
          })

          this.ToggleSettingRow('Include images', !this.imageWifiOnly, (v) => {
            SettingsRepository.getInstance().putBoolean('image_wifi_only', !v)
          })

          this.SelectRow('Max feed items', this.maxFeedItems.toString(),
            ['50', '100', '200', '500'],
            'max_feed_items')

          this.SelectRow('Open links with', this.openLinkWith,
            ['Custom tab', 'Web browser'],
            'open_link_with')

          // === Advanced section ===
          this.SectionHeader('Advanced')

          this.ClickRow('Block list', () => {
            this.openBlockListDialog()
          })

          this.ClickRow('Device sync', () => {
            router.pushUrl({ url: 'pages/DeviceSync' })
          })

          this.ClickRow('Text settings', () => {
            router.pushUrl({ url: 'pages/TextSettings' })
          })

          this.ClickRow('Send bug report', () => {
          })
        }
        .width('100%')
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)

      // Selection dialog
      if (this.selectVisible) {
        this.SelectionDialog()
      }

      // Block list dialog
      if (this.blockListDialogVisible) {
        this.BlockListDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fafafa')
  }

  @Builder
  SectionHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.primary'))
      .margin({ left: 16, top: 16, bottom: 8 })
      .width('100%')
  }

  @Builder
  ToggleSettingRow(title: string, isOn: boolean, onChange: (value: boolean) => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#212121')
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
        .selectedColor($r('app.color.primary'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#ffffff')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SelectRow(title: string, currentValue: string, options: string[], settingsKey: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#212121')

        Text(currentValue)
          .fontSize(13)
          .fontColor('#757575')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_arrow_right'))
        .width(20)
        .height(20)
        .fillColor('#9e9e9e')
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#ffffff')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectKey = settingsKey
      this.selectTitle = title
      this.selectOptions = options
      this.selectVisible = true
    })
  }

  @Builder
  ClickRow(title: string, action: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#212121')
        .layoutWeight(1)

      Image($r('app.media.ic_arrow_right'))
        .width(20)
        .height(20)
        .fillColor('#9e9e9e')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#ffffff')
    .alignItems(VerticalAlign.Center)
    .onClick(action)
  }

  @Builder
  SelectionDialog() {
    Column() {
      Text(this.selectTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      ForEach(this.selectOptions, (option: string) => {
        Row() {
          Text(option)
            .fontSize(16)
            .fontColor(this.getSelectCurrentValue() === option ? $r('app.color.primary') : '#212121')
            .layoutWeight(1)

          if (this.getSelectCurrentValue() === option) {
            Image($r('app.media.ic_check'))
              .width(20)
              .height(20)
              .fillColor($r('app.color.primary'))
          }
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.applySetting(this.selectKey, option)
          this.selectVisible = false
        })
      }, (option: string, index: number) => `${this.selectKey}_${index}`)
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#ffffff')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#33000000' })
  }

  @Builder
  BlockListDialog() {
    Column() {
      Text('Block list')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      // Apply to summaries toggle
      Row() {
        Text('Apply to summaries')
          .fontSize(16)
          .fontColor('#212121')
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.blockListApplySummaries })
          .onChange((v: boolean) => {
          })
          .selectedColor($r('app.color.primary'))
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })

      Divider().margin({ top: 4, bottom: 4 })

      // Add pattern
      Row() {
        TextInput({ text: this.newBlockPattern, placeholder: 'Pattern (e.g. spam*)' })
          .layoutWeight(1)
          .height(40)
          .borderRadius(4)
          .border({ width: 1, color: '#bdbdbd' })
          .onChange((v: string) => {
            this.newBlockPattern = v
          })

        Button('Add')
          .fontSize(14)
          .fontColor('#ffffff')
          .backgroundColor($r('app.color.primary'))
          .borderRadius(4)
          .height(40)
          .margin({ left: 8 })
          .key('block_add_pattern_btn')
          .enabled(this.newBlockPattern.length > 0)
          .onClick(async () => {
            this.newBlockPattern = ''
          })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })

      // Pattern list -- always empty
      List() {
        ForEach(this.blockListPatterns, (entry: BlocklistEntry) => {
          ListItem() {
            Row() {
              Text(entry.pattern)
                .fontSize(14)
                .fontColor('#212121')
                .layoutWeight(1)

              Button('Remove')
                .fontSize(12)
                .fontColor('#d32f2f')
                .backgroundColor(Color.Transparent)
                .onClick(async () => {
                })
            }
            .width('100%')
            .height(40)
            .padding({ left: 8, right: 8 })
          }
        }, (entry: BlocklistEntry) => entry.id.toString())
      }
      .width('100%')
      .height(200)

      Button('Close')
        .fontSize(14)
        .fontColor('#757575')
        .backgroundColor(Color.Transparent)
        .margin({ top: 16 })
        .onClick(() => {
          this.blockListDialogVisible = false
        })
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#ffffff')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#33000000' })
  }

  // Helper: get current value for a settings key
  private getSelectCurrentValue(): string {
    const settingsRepo = SettingsRepository.getInstance()
    return settingsRepo.getString(this.selectKey, '')
  }

  private applySetting(key: string, value: string) {
    const settingsRepo = SettingsRepository.getInstance()
    // Check if this is a number-type setting
    if (key === 'max_feed_items' || key === 'max_lines') {
      settingsRepo.putNumber(key, parseInt(value))
    } else {
      settingsRepo.putString(key, value)
    }
  }

  private async openBlockListDialog() {
    this.blockListDialogVisible = true
    await this.loadBlockListPatterns()
  }

  private async loadBlockListPatterns() {
    try {
      const blocklistRepo = BlocklistRepository.getInstance()
      this.blockListPatterns = await blocklistRepo.getAllPatterns()
    } catch (err) {
      this.blockListPatterns = []
    }
  }
}
