// FeedRepository.ets -- Feed CRUD, query by tag, unread counts

import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from './DatabaseHelper'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'FeedRepository'

export interface FeedRow {
  id: number
  url: string
  title: string
  tag: string
  notify: boolean
  fullTextByDefault: boolean
  summarizeOnOpen: boolean
  fetchOgImages: boolean
  skipDuplicates: boolean
  alternateId: boolean
  articleOpener: string
  currentlySyncing: boolean
  lastSync: number
  retryAfter: number
}

export function feedRowFromBucket(bucket: relationalStore.ValuesBucket): FeedRow {
  return {
    id: (bucket['id'] as number) ?? 0,
    url: (bucket['url'] as string) ?? '',
    title: (bucket['title'] as string) ?? '',
    tag: (bucket['tag'] as string) ?? '',
    notify: ((bucket['notify'] as number) ?? 0) === 1,
    fullTextByDefault: ((bucket['fullTextByDefault'] as number) ?? 0) === 1,
    summarizeOnOpen: ((bucket['summarizeOnOpen'] as number) ?? 0) === 1,
    fetchOgImages: ((bucket['fetchOgImages'] as number) ?? 0) === 1,
    skipDuplicates: ((bucket['skipDuplicates'] as number) ?? 0) === 1,
    alternateId: ((bucket['alternateId'] as number) ?? 0) === 1,
    articleOpener: (bucket['articleOpener'] as string) ?? 'default',
    currentlySyncing: ((bucket['currentlySyncing'] as number) ?? 0) === 1,
    lastSync: (bucket['lastSync'] as number) ?? 0,
    retryAfter: (bucket['retryAfter'] as number) ?? 0,
  }
}

export class FeedRepository {
  private static instance: FeedRepository | null = null

  private constructor() {}

  static getInstance(): FeedRepository {
    if (!FeedRepository.instance) {
      FeedRepository.instance = new FeedRepository()
    }
    return FeedRepository.instance
  }

  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore()
  }

  async insertFeed(url: string, title: string, tag: string): Promise<number> {
  // Public shell stub: add-feed mutation is intentionally absent.
    return 0
  }

  async updateFeed(feed: FeedRow): Promise<number> {
  // Public shell stub: edit-feed mutation is intentionally absent.
    return 0
  }

  async deleteFeed(feedId: number): Promise<number> {
  // Public shell stub: delete-feed mutation is intentionally absent.
    return 0
  }

  async deleteFeedsByIds(feedIds: number[]): Promise<number> {
  // Public shell stub: delete-feed mutation is intentionally absent.
    return 0
  }

  async getAllFeeds(): Promise<FeedRow[]> {
    const store = this.getStore()
    const predicates = new relationalStore.RdbPredicates('feeds')
    predicates.orderByAsc('title')
    const resultSet = await store.query(predicates)
    const feeds: FeedRow[] = []
    try {
      while (resultSet.goToNextRow()) {
        const bucket = resultSet.getRow()
        feeds.push(feedRowFromBucket(bucket))
      }
    } finally {
      resultSet.close()
    }
    return feeds
  }

  async getFeedsByTag(tag: string): Promise<FeedRow[]> {
    const store = this.getStore()
    const predicates = new relationalStore.RdbPredicates('feeds')
    if (tag.length > 0) {
      predicates.equalTo('tag', tag)
    }
    predicates.orderByAsc('title')
    const resultSet = await store.query(predicates)
    const feeds: FeedRow[] = []
    try {
      while (resultSet.goToNextRow()) {
        const bucket = resultSet.getRow()
        feeds.push(feedRowFromBucket(bucket))
      }
    } finally {
      resultSet.close()
    }
    return feeds
  }

  async getDistinctTags(): Promise<string[]> {
    const store = this.getStore()
    const sql = 'SELECT DISTINCT tag FROM feeds WHERE tag != "" ORDER BY tag'
    const resultSet = await store.querySql(sql)
    const tags: string[] = []
    try {
      while (resultSet.goToNextRow()) {
        const bucket = resultSet.getRow()
        const tag = (bucket['tag'] as string) ?? ''
        if (tag.length > 0) {
          tags.push(tag)
        }
      }
    } finally {
      resultSet.close()
    }
    return tags
  }

  async getFeedById(feedId: number): Promise<FeedRow | null> {
    const store = this.getStore()
    const predicates = new relationalStore.RdbPredicates('feeds')
    predicates.equalTo('id', feedId)
    const resultSet = await store.query(predicates)
    try {
      if (resultSet.goToNextRow()) {
        return feedRowFromBucket(resultSet.getRow())
      }
    } finally {
      resultSet.close()
    }
    return null
  }

  async getUnreadCountByFeed(feedId: number): Promise<number> {
    const store = this.getStore()
    const sql = 'SELECT COUNT(*) as cnt FROM feed_items WHERE feed_id = ? AND unread = 1'
    const resultSet = await store.querySql(sql, [feedId.toString()])
    try {
      if (resultSet.goToNextRow()) {
        const bucket = resultSet.getRow()
        return (bucket['cnt'] as number) ?? 0
      }
    } finally {
      resultSet.close()
    }
    return 0
  }

  async getTotalUnreadCount(): Promise<number> {
    const store = this.getStore()
    const sql = 'SELECT COUNT(*) as cnt FROM feed_items WHERE unread = 1'
    const resultSet = await store.querySql(sql)
    try {
      if (resultSet.goToNextRow()) {
        const bucket = resultSet.getRow()
        return (bucket['cnt'] as number) ?? 0
      }
    } finally {
      resultSet.close()
    }
    return 0
  }

  async getUnreadCountByTag(tag: string): Promise<number> {
    const store = this.getStore()
    const sql = 'SELECT COUNT(*) as cnt FROM feed_items fi JOIN feeds f ON fi.feed_id = f.id WHERE f.tag = ? AND fi.unread = 1'
    const resultSet = await store.querySql(sql, [tag])
    try {
      if (resultSet.goToNextRow()) {
        const bucket = resultSet.getRow()
        return (bucket['cnt'] as number) ?? 0
      }
    } finally {
      resultSet.close()
    }
    return 0
  }

  async updateLastSync(feedId: number): Promise<void> {
  // Public shell stub: sync state mutation is intentionally absent.
  }

  async setCurrentlySyncing(feedId: number, syncing: boolean): Promise<void> {
  // Public shell stub: sync state mutation is intentionally absent.
  }

  async seedFeed(url: string, title: string, tag: string): Promise<number> {
  // Stable mock content for UI reachability.
    const store = this.getStore()
    // Check if feed with this URL already exists
    const checkSql = 'SELECT id FROM feeds WHERE url = ?'
    const existing = await store.querySql(checkSql, [url])
    try {
      if (existing.goToNextRow()) {
        const existingId = existing.getRow()['id'] as number
        existing.close()
        hilog.info(DOMAIN, TAG, 'Feed already exists id=%{public}d url=%{public}s', existingId, url)
        return existingId
      }
    } catch (err) {
      // Ignore
    }
    try {
      existing.close()
    } catch (e) {
      // Ignore
    }
    return this.insertFeedRaw(url, title, tag)
  }

  private async insertFeedRaw(url: string, title: string, tag: string): Promise<number> {
    const store = this.getStore()
    const valueBucket: relationalStore.ValuesBucket = {
      url: url,
      title: title,
      tag: tag,
    }
    const rowId = await store.insert('feeds', valueBucket)
    hilog.info(DOMAIN, TAG, 'Seeded feed id=%{public}d url=%{public}s', rowId, url)
    return rowId
  }
}
