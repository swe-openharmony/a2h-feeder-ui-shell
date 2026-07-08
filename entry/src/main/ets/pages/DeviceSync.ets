// Device Sync page - Sync chain management

import { router } from '@kit.ArkUI'
import { SettingsRepository } from '../repository/SettingsRepository'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'DeviceSync'

@Entry
@Component
struct DeviceSync {
  @State syncCode: string = ''
  @State secretKey: string = ''
  @State isSyncing: boolean = false
  @State leaveDialogVisible: boolean = false

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

        Text('Device sync')
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
          // Scan or enter code section
          Text('Scan or enter code')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121')
            .margin({ top: 24, bottom: 8 })

          Text('Enter the sync code from another device to join its sync chain, or start a new chain.')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ bottom: 16 })

          // Sync code input
          Row() {
            TextInput({ text: this.syncCode, placeholder: 'Sync code' })
              .layoutWeight(1)
              .height(48)
              .borderRadius(8)
              .border({ width: 1, color: '#bdbdbd' })
              .onChange((v: string) => {
                this.syncCode = v
              })
              .key('sync_code_input')
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // Secret key input
          Row() {
            TextInput({ text: this.secretKey, placeholder: 'Secret key' })
              .layoutWeight(1)
              .height(48)
              .borderRadius(8)
              .border({ width: 1, color: '#bdbdbd' })
              .onChange((v: string) => {
                this.secretKey = v
              })
              .key('sync_secret_key_input')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8 })

          // Join sync chain button
          Button('Join sync chain')
            .width('90%')
            .height(48)
            .fontSize(16)
            .fontColor('#ffffff')
            .backgroundColor($r('app.color.primary'))
            .borderRadius(8)
            .margin({ top: 24 })
            .enabled(this.syncCode.length > 0 && this.secretKey.length > 0)
            .key('sync_join_btn')
            .onClick(() => {
              hilog.info(DOMAIN, TAG, 'Join sync chain (stub)')
              this.isSyncing = true
            })

          // Divider
          Divider()
            .margin({ top: 32, bottom: 16 })
            .padding({ left: 16, right: 16 })

          // Start new sync chain
          Text('Start new sync chain')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#212121')
            .margin({ bottom: 8 })

          Text('Create a new sync chain and add other devices to it.')
            .fontSize(14)
            .fontColor('#757575')
            .margin({ bottom: 16 })

          Button('Start new sync chain')
            .width('90%')
            .height(48)
            .fontSize(16)
            .fontColor($r('app.color.primary'))
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: $r('app.color.primary') })
            .borderRadius(8)
            .key('sync_start_new_btn')
            .onClick(() => {
              hilog.info(DOMAIN, TAG, 'Start new sync chain (stub)')
            })

          // Add new device
          Button('Add new device')
            .width('90%')
            .height(48)
            .fontSize(16)
            .fontColor($r('app.color.primary'))
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: $r('app.color.primary') })
            .borderRadius(8)
            .margin({ top: 12 })
            .key('sync_add_device_btn')
            .onClick(() => {
              hilog.info(DOMAIN, TAG, 'Add new device (stub)')
            })

          // Leave sync chain
          Button('Leave sync chain')
            .width('90%')
            .height(48)
            .fontSize(16)
            .fontColor('#d32f2f')
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: '#d32f2f' })
            .borderRadius(8)
            .margin({ top: 32 })
            .key('sync_leave_btn')
            .onClick(() => {
              this.leaveDialogVisible = true
            })
        }
        .width('100%')
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)

      // Leave sync chain dialog
      if (this.leaveDialogVisible) {
        this.LeaveSyncDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fafafa')
  }

  @Builder
  LeaveSyncDialog() {
    Column() {
      Text('Leave sync chain')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      Text('Are you sure you want to leave the sync chain? Your local data will be preserved.')
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
            this.leaveDialogVisible = false
          })

        Button('Leave')
          .fontSize(14)
          .fontColor('#d32f2f')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => {
            hilog.info(DOMAIN, TAG, 'Left sync chain (stub)')
            this.leaveDialogVisible = false
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#ffffff')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#33000000' })
  }
}
