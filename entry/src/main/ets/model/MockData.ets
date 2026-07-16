// Data models for Feeder RSS Reader
// Interface definitions only -- data comes from Repository layer, not mock constants

export interface FeedItem {
  id: number
  title: string
  url: string
  tag: string
  unreadCount: number
  notify: boolean
}

export interface ArticleItem {
  id: number
  feedId: number
  feedTitle: string
  title: string
  snippet: string
  link: string
  pubDate: string
  read: boolean
  saved: boolean
  thumbnail: string
}

export interface FeedConfig {
  url: string
  title: string
  tag: string
  fetchFullArticles: boolean
  summarizeOnOpen: boolean
  enhanceThumbnails: boolean
  notifyForNewItems: boolean
  skipDuplicates: boolean
  generateExtraIds: boolean
  openWith: string // 'default' | 'reader' | 'browser'
}

// Filter options
export const FILTER_OPTIONS: string[] = [
  'Unread',
  'Saved',
  'Recently Read',
  'Read',
]

// Settings sections from Android string resources
export interface SettingItem {
  key: string
  title: string
  subtitle?: string
  type: 'toggle' | 'click' | 'select'
  value?: string | boolean
  options?: string[]
}

export interface SettingSection {
  title: string
  items: SettingItem[]
}
