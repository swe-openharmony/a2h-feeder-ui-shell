// ArticleRepository.ets -- Article CRUD, markRead, toggleBookmark, search, filter

import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from './DatabaseHelper'
import { ParsedFeedItem } from '../service/RssParser'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'ArticleRepository'

export interface ArticleRow {
  id: number
  guid: string
  feedId: number
  title: string
  plainTitle: string
  plainSnippet: string
  link: string
  imageUrl: string
  pubDate: number
  author: string
  enclosureLink: string
  enclosureType: string
  bookmarked: boolean
  unread: boolean
  notified: boolean
  blocked: boolean
  wordCount: number
  fullTextByDefault: boolean
  fullTextDownloaded: boolean
  primarySortTime: number
  htmlContent: string
  scrollPosition: number
  // Joined field
  feedTitle: string
}

export function articleRowFromBucket(bucket: relationalStore.ValuesBucket): ArticleRow {
  return {
    id: (bucket['id'] as number) ?? 0,
    guid: (bucket['guid'] as string) ?? '',
    feedId: (bucket['feed_id'] as number) ?? 0,
    title: (bucket['title'] as string) ?? '',
    plainTitle: (bucket['plainTitle'] as string) ?? '',
    plainSnippet: (bucket['plainSnippet'] as string) ?? '',
    link: (bucket['link'] as string) ?? '',
    imageUrl: (bucket['imageUrl'] as string) ?? '',
    pubDate: (bucket['pubDate'] as number) ?? 0,
    author: (bucket['author'] as string) ?? '',
    enclosureLink: (bucket['enclosureLink'] as string) ?? '',
    enclosureType: (bucket['enclosureType'] as string) ?? '',
    bookmarked: ((bucket['bookmarked'] as number) ?? 0) === 1,
    unread: ((bucket['unread'] as number) ?? 1) === 1,
    notified: ((bucket['notified'] as number) ?? 0) === 1,
    blocked: ((bucket['blocked'] as number) ?? 0) === 1,
    wordCount: (bucket['wordCount'] as number) ?? 0,
    fullTextByDefault: ((bucket['fullTextByDefault'] as number) ?? 0) === 1,
    fullTextDownloaded: ((bucket['fullTextDownloaded'] as number) ?? 0) === 1,
    primarySortTime: (bucket['primarySortTime'] as number) ?? 0,
    htmlContent: (bucket['htmlContent'] as string) ?? '',
    scrollPosition: (bucket['scrollPosition'] as number) ?? 0,
    feedTitle: (bucket['feedTitle'] as string) ?? '',
  }
}

export class ArticleRepository {
  private static instance: ArticleRepository | null = null

  private constructor() {}

  static getInstance(): ArticleRepository {
    if (!ArticleRepository.instance) {
      ArticleRepository.instance = new ArticleRepository()
    }
    return ArticleRepository.instance
  }

  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore()
  }

  // Public shell fallback: no query matching is implemented here.
  async searchArticles(query: string): Promise<ArticleRow[]> {
    return []
  }

  async getArticlesByFeed(feedId: number, filterUnread: boolean = true,
                          filterSaved: boolean = false, filterRead: boolean = false,
                          filterRecentlyRead: boolean = false,
                          sortOrder: string = 'DESC'): Promise<ArticleRow[]> {
    const store = this.getStore()
    let whereClauses = ['fi.blocked = 0']
    const args: string[] = []

    if (feedId > 0) {
      whereClauses.push('fi.feed_id = ?')
      args.push(feedId.toString())
    }

    if (filterUnread && !filterSaved && !filterRead) {
      whereClauses.push('fi.unread = 1')
    }
    if (filterSaved) {
      whereClauses.push('fi.bookmarked = 1')
    }
    if (filterRead) {
      whereClauses.push('fi.unread = 0')
    }
    if (filterRecentlyRead) {
      // Articles marked read in the last 24 hours
      const cutoff = Date.now() - 24 * 60 * 60 * 1000
      whereClauses.push('fi.unread = 0 AND fi.primarySortTime > ?')
      args.push(cutoff.toString())
    }

    const whereClause = whereClauses.join(' AND ')
    const sql = `SELECT fi.*, f.title as feedTitle FROM feed_items fi
      JOIN feeds f ON fi.feed_id = f.id
      WHERE ${whereClause}
      ORDER BY fi.primarySortTime ${sortOrder}`
    const resultSet = await store.querySql(sql, args)
    return this.collectArticles(resultSet)
  }

  async getSavedArticles(): Promise<ArticleRow[]> {
    const store = this.getStore()
    const sql = `SELECT fi.*, f.title as feedTitle FROM feed_items fi
      JOIN feeds f ON fi.feed_id = f.id
      WHERE fi.bookmarked = 1 AND fi.blocked = 0
      ORDER BY fi.primarySortTime DESC`
    const resultSet = await store.querySql(sql)
    return this.collectArticles(resultSet)
  }

  async getArticleById(articleId: number): Promise<ArticleRow | null> {
    const store = this.getStore()
    const sql = `SELECT fi.*, f.title as feedTitle FROM feed_items fi
      JOIN feeds f ON fi.feed_id = f.id
      WHERE fi.id = ?`
    const resultSet = await store.querySql(sql, [articleId.toString()])
    try {
      if (resultSet.goToNextRow()) {
        return articleRowFromBucket(resultSet.getRow())
      }
    } finally {
      resultSet.close()
    }
    return null
  }

  async markAllRead(feedId: number = 0): Promise<number> {
  // Public shell stub: read state mutation is intentionally absent.
    return 0
  }

  async markRead(articleId: number): Promise<void> {
  // Public shell stub: read state mutation is intentionally absent.
  }

  async markUnread(articleId: number): Promise<void> {
  // Public shell stub: read state mutation is intentionally absent.
  }

  async toggleBookmark(articleId: number): Promise<boolean> {
  // Public shell stub: bookmark mutation is intentionally absent.
    return false
  }

  async setBookmarked(articleId: number, bookmarked: boolean): Promise<void> {
  // Public shell stub: bookmark mutation is intentionally absent.
  }

  async toggleReadStatus(articleId: number): Promise<boolean> {
  // Public shell stub: read state mutation is intentionally absent.
    return false
  }

  async markAboveAsRead(articleId: number, feedId: number): Promise<number> {
  // Public shell stub: read state mutation is intentionally absent.
    return 0
  }

  async markBelowAsRead(articleId: number, feedId: number): Promise<number> {
  // Public shell stub: read state mutation is intentionally absent.
    return 0
  }

  async updateHtmlContent(articleId: number, htmlContent: string): Promise<void> {
  // Public shell stub: full-text loading is intentionally absent.
  }

  async saveScrollPosition(articleId: number, scrollPosition: number): Promise<void> {
  // Public shell stub: reader state mutation is intentionally absent.
  }

  async upsertParsedItems(feedId: number, items: ParsedFeedItem[]): Promise<number> {
  // Public shell stub: sync state mutation is intentionally absent.
    return 0
  }

  async seedArticle(feedId: number, title: string, snippet: string, link: string,
                    pubDate: number, htmlContent: string, guid: string = '',
                    imageUrl: string = '', author: string = '',
                    unread: boolean = true, bookmarked: boolean = false): Promise<number> {
  // Stable mock content for UI reachability.
    const store = this.getStore()
    // Use a deterministic guid based on feedId + title to prevent duplicates
    const effectiveGuid = guid.length > 0 ? guid : `seed-${feedId}-${title}`
    // Check if article with this guid already exists
    const checkSql = 'SELECT id FROM feed_items WHERE guid = ?'
    const existing = await store.querySql(checkSql, [effectiveGuid])
    try {
      if (existing.goToNextRow()) {
        // Article already exists, update it instead of inserting duplicate
        const existingId = existing.getRow()['id'] as number
        existing.close()
        const updateBucket: relationalStore.ValuesBucket = {
          title: title,
          plainTitle: title,
          plainSnippet: snippet,
          link: link,
          pubDate: pubDate,
          htmlContent: htmlContent,
          primarySortTime: pubDate,
          unread: unread ? 1 : 0,
          bookmarked: bookmarked ? 1 : 0,
        }
        const predicates = new relationalStore.RdbPredicates('feed_items')
        predicates.equalTo('id', existingId)
        await store.update(updateBucket, predicates)
        return existingId
      }
    } catch (err) {
      // Ignore check errors, proceed to insert
    }
    try {
      existing.close()
    } catch (e) {
      // Ignore
    }
    const valueBucket: relationalStore.ValuesBucket = {
      guid: effectiveGuid,
      feed_id: feedId,
      title: title,
      plainTitle: title,
      plainSnippet: snippet,
      link: link,
      pubDate: pubDate,
      author: author,
      imageUrl: imageUrl,
      htmlContent: htmlContent,
      primarySortTime: pubDate,
      unread: unread ? 1 : 0,
      bookmarked: bookmarked ? 1 : 0,
    }
    return store.insert('feed_items', valueBucket)
  }

  async resetAllToUnread(): Promise<void> {
  // Restores the stable mock unread list at launch.
    const store = this.getStore()
    const sql = 'UPDATE feed_items SET unread = 1'
    await store.executeSql(sql, [])
    hilog.info(DOMAIN, TAG, 'All articles reset to unread')
  }

  private collectArticles(resultSet: relationalStore.ResultSet): ArticleRow[] {
    const articles: ArticleRow[] = []
    try {
      while (resultSet.goToNextRow()) {
        articles.push(articleRowFromBucket(resultSet.getRow()))
      }
    } finally {
      resultSet.close()
    }
    return articles
  }
}
