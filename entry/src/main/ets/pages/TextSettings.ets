// Text Settings page - Font and text display settings
// UI skeleton and navigation preserved

import { router } from '@kit.ArkUI'
import { SettingsRepository } from '../repository/SettingsRepository'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'TextSettings'

@Entry
@Component
struct TextSettings {
  @StorageLink('font_size') fontSize: string = 'Medium'
  @StorageLink('font_family') fontFamily: string = 'Default'
  @StorageLink('text_alignment') textAlignment: string = 'Left'
  @StorageLink('line_spacing') lineSpacing: string = 'Normal'
  @StorageLink('article_text_zoom') textZoom: number = 100

  @State selectVisible: boolean = false
  @State selectKey: string = ''
  @State selectOptions: string[] = []
  @State selectTitle: string = ''

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

        Text('Text settings')
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
          // === Font section ===
          this.SectionHeader('Font')

          this.SelectRow('Font size', this.fontSize,
            ['Small', 'Medium', 'Large', 'Extra Large'],
            'font_size')

          this.SelectRow('Font family', this.fontFamily,
            ['Default', 'Serif', 'Sans-serif', 'Monospace'],
            'font_family')

          // Add font button
          Row() {
            Text('Add font')
              .fontSize(16)
              .fontColor($r('app.color.primary'))
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
          .onClick(() => {
          })

          // === Text display section ===
          this.SectionHeader('Text display')

          this.SelectRow('Text alignment', this.textAlignment,
            ['Left', 'Center', 'Justify'],
            'text_alignment')

          this.SelectRow('Line spacing', this.lineSpacing,
            ['Compact', 'Normal', 'Relaxed'],
            'line_spacing')

          // Text zoom
          Row() {
            Column() {
              Text('Text zoom')
                .fontSize(16)
                .fontColor('#212121')

              Text(`${this.textZoom}%`)
                .fontSize(13)
                .fontColor('#757575')
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Slider({
              value: this.textZoom,
              min: 50,
              max: 200,
              step: 10
            })
              .width('50%')
              .trackColor('#e0e0e0')
              .selectedColor($r('app.color.primary'))
              .onChange((value: number) => {
                this.textZoom = Math.round(value)
              })
          }
          .width('100%')
          .height(64)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#ffffff')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)

      // Selection dialog
      if (this.selectVisible) {
        this.SelectionDialog()
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
            .fontColor(this.getCurrentValue() === option ? $r('app.color.primary') : '#212121')
            .layoutWeight(1)

          if (this.getCurrentValue() === option) {
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
          const repo = SettingsRepository.getInstance()
          repo.putString(this.selectKey, option)
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

  private getCurrentValue(): string {
    const repo = SettingsRepository.getInstance()
    return repo.getString(this.selectKey, '')
  }
}
