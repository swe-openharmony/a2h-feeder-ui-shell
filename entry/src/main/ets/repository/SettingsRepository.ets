// SettingsRepository.ets -- Preferences wrapper for all 40+ settings keys

import { preferences } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'SettingsRepository'
const PREFS_NAME = 'feeder_settings'

// Default settings values
export const DEFAULT_SETTINGS: Record<string, string | boolean | number> = {
  // Theme
  'theme': 'Day',
  'dark_theme_preference': 'Dark',

  // Sync
  'sync_frequency': 'Manually',
  'sync_on_startup': false,
  'sync_on_wifi_only': false,
  'sync_on_charging_only': false,
  'max_feed_items': 100,

  // Display
  'show_thumbnails': true,
  'sort_order': 'Newest first',
  'swipe_to_mark_read': 'Only from end',
  'mark_as_read_on_scroll': false,
  'show_fab': true,
  'open_drawer_on_fab': false,
  'feed_item_style': 'Card',
  'max_lines': 2,
  'show_only_title': false,
  'show_reading_time': false,
  'show_title_unread_count': false,

  // Article
  'open_item_with': 'Reader',
  'open_link_with': 'Custom tab',
  'open_browser_split_screen': false,
  'paging_mode': false,
  'animated_paging': false,
  'image_wifi_only': false,

  // Block list
  'block_list_apply_summaries': false,

  // TTS
  'tts_detect_language': true,

  // Translation / Summarization
  'translate_feed_cards': false,
  'translate_articles': false,

  // Notify
  'notify_new_items': false,
}

export class SettingsRepository {
  private static instance: SettingsRepository | null = null
  private prefs: preferences.Preferences | null = null

  private constructor() {}

  static getInstance(): SettingsRepository {
    if (!SettingsRepository.instance) {
      SettingsRepository.instance = new SettingsRepository()
    }
    return SettingsRepository.instance
  }

  async init(context: Context): Promise<void> {
    if (this.prefs !== null) {
      return
    }
    try {
      this.prefs = await preferences.getPreferences(context, PREFS_NAME)
      hilog.info(DOMAIN, TAG, 'Settings preferences initialized')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Settings init failed: %{public}s', JSON.stringify(err))
      throw new Error('Settings init failed')
    }
  }

  private ensurePrefs(): preferences.Preferences {
    if (this.prefs === null) {
      throw new Error('SettingsRepository not initialized. Call init() first.')
    }
    return this.prefs
  }

  private getDefaultValue(key: string): string | boolean | number | undefined {
    const keys = Object.keys(DEFAULT_SETTINGS)
    for (let i = 0; i < keys.length; i++) {
      if (keys[i] === key) {
        return DEFAULT_SETTINGS[key]
      }
    }
    return undefined
  }

  getString(key: string, defaultValue: string = ''): string {
    const val = this.getDefaultValue(key)
    if (typeof val === 'string') {
      return val as string
    }
    return defaultValue
  }

  getBoolean(key: string, defaultValue: boolean = false): boolean {
    const val = this.getDefaultValue(key)
    if (typeof val === 'boolean') {
      return val as boolean
    }
    return defaultValue
  }

  getNumber(key: string, defaultValue: number = 0): number {
    const val = this.getDefaultValue(key)
    if (typeof val === 'number') {
      return val as number
    }
    return defaultValue
  }

  putString(key: string, value: string): void {
    // No disk write, but update AppStorage for reactive UI
    AppStorage.setOrCreate(key, value)
  }

  putBoolean(key: string, value: boolean): void {
    AppStorage.setOrCreate(key, value)
  }

  putNumber(key: string, value: number): void {
    AppStorage.setOrCreate(key, value)
  }

  loadAllToAppStorage(): void {
    const keys = Object.keys(DEFAULT_SETTINGS)
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i]
      const value = DEFAULT_SETTINGS[key]
      if (typeof value === 'string') {
        AppStorage.setOrCreate(key, value as string)
      } else if (typeof value === 'boolean') {
        AppStorage.setOrCreate(key, value as boolean)
      } else if (typeof value === 'number') {
        AppStorage.setOrCreate(key, value as number)
      }
    }
  }

  // Test helper: clear all settings
  async clearAll(): Promise<void> {
    const p = this.ensurePrefs()
    await p.clear()
    await p.flush()
  }
}
