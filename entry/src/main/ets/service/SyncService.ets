// SyncService.ets -- Orchestrates feed sync: HTTP fetch -> parse -> upsert to DB

import { http } from '@kit.NetworkKit'
import { util } from '@kit.ArkTS'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { FeedRepository } from '../repository/FeedRepository'
import { ArticleRepository, ArticleRow } from '../repository/ArticleRepository'
import { SettingsRepository } from '../repository/SettingsRepository'
import { parseRssFeed, discoverFeeds, parseFeedMeta, ParsedFeedItem, DiscoveryResult } from './RssParser'

const DOMAIN = 0x0000
const TAG = 'SyncService'

export interface SyncProgress {
  inProgress: boolean
  currentFeed: string
  feedsCompleted: number
  feedsTotal: number
  error: string
}

export class SyncService {
  private static instance: SyncService | null = null
  private syncInProgress: boolean = false

  private constructor() {}

  static getInstance(): SyncService {
    if (!SyncService.instance) {
      SyncService.instance = new SyncService()
    }
    return SyncService.instance
  }

  isSyncing(): boolean {
  // Public shell stub: sync request is intentionally absent.
    return false
  }

  async syncAllFeeds(): Promise<void> {
  // Public shell stub: sync request is intentionally absent.
  }

  async syncFeed(feedId: number, feedUrl: string): Promise<number> {
  // Public shell stub: sync request is intentionally absent.
    return 0
  }

  async searchFeed(url: string): Promise<DiscoveryResult[]> {
  // Public shell stub: remote feed search is intentionally absent.
    return []
  }

  async fetchFullArticle(articleLink: string): Promise<string> {
  // Public shell stub: full-text fetch is intentionally absent.
    return ''
  }
}
