// DatabaseHelper.ets -- RdbStore singleton, table creation SQL

import { relationalStore } from '@kit.ArkData'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'DatabaseHelper'
const DB_NAME = 'feeder.db'
const DB_VERSION = 1

const CREATE_FEEDS_TABLE = `
  CREATE TABLE IF NOT EXISTS feeds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT NOT NULL,
    title TEXT NOT NULL DEFAULT '',
    tag TEXT NOT NULL DEFAULT '',
    notify INTEGER NOT NULL DEFAULT 0,
    fullTextByDefault INTEGER NOT NULL DEFAULT 0,
    summarizeOnOpen INTEGER NOT NULL DEFAULT 0,
    fetchOgImages INTEGER NOT NULL DEFAULT 0,
    skipDuplicates INTEGER NOT NULL DEFAULT 0,
    alternateId INTEGER NOT NULL DEFAULT 0,
    articleOpener TEXT NOT NULL DEFAULT 'default',
    currentlySyncing INTEGER NOT NULL DEFAULT 0,
    lastSync INTEGER,
    retryAfter INTEGER
  )
`

const CREATE_FEED_ITEMS_TABLE = `
  CREATE TABLE IF NOT EXISTS feed_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT NOT NULL,
    feed_id INTEGER NOT NULL,
    title TEXT NOT NULL DEFAULT '',
    plainTitle TEXT NOT NULL DEFAULT '',
    plainSnippet TEXT NOT NULL DEFAULT '',
    link TEXT NOT NULL DEFAULT '',
    imageUrl TEXT NOT NULL DEFAULT '',
    pubDate INTEGER,
    author TEXT NOT NULL DEFAULT '',
    enclosureLink TEXT NOT NULL DEFAULT '',
    enclosureType TEXT NOT NULL DEFAULT '',
    bookmarked INTEGER NOT NULL DEFAULT 0,
    unread INTEGER NOT NULL DEFAULT 1,
    notified INTEGER NOT NULL DEFAULT 0,
    blocked INTEGER NOT NULL DEFAULT 0,
    wordCount INTEGER NOT NULL DEFAULT 0,
    fullTextByDefault INTEGER NOT NULL DEFAULT 0,
    fullTextDownloaded INTEGER NOT NULL DEFAULT 0,
    primarySortTime INTEGER,
    htmlContent TEXT NOT NULL DEFAULT '',
    scrollPosition INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (feed_id) REFERENCES feeds(id) ON DELETE CASCADE
  )
`

const CREATE_BLOCKLIST_TABLE = `
  CREATE TABLE IF NOT EXISTS blocklist (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern TEXT NOT NULL
  )
`

const CREATE_SEARCH_RESULTS_TABLE = `
  CREATE TABLE IF NOT EXISTS search_feed_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT NOT NULL,
    title TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    streamUrl TEXT NOT NULL DEFAULT ''
  )
`

// Indexes for common queries
const CREATE_INDEX_FEED_ITEMS_FEED_ID = `
  CREATE INDEX IF NOT EXISTS idx_feed_items_feed_id ON feed_items(feed_id)
`
const CREATE_INDEX_FEED_ITEMS_UNREAD = `
  CREATE INDEX IF NOT EXISTS idx_feed_items_unread ON feed_items(unread)
`
const CREATE_INDEX_FEED_ITEMS_BOOKMARKED = `
  CREATE INDEX IF NOT EXISTS idx_feed_items_bookmarked ON feed_items(bookmarked)
`
const CREATE_INDEX_FEED_ITEMS_PUBDATE = `
  CREATE INDEX IF NOT EXISTS idx_feed_items_pubdate ON feed_items(primarySortTime)
`
const CREATE_INDEX_FEEDS_TAG = `
  CREATE INDEX IF NOT EXISTS idx_feeds_tag ON feeds(tag)
`

export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null
  private rdbStore: relationalStore.RdbStore | null = null
  private initPromise: Promise<relationalStore.RdbStore> | null = null

  private constructor() {}

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  async init(context: Context): Promise<relationalStore.RdbStore> {
    if (this.rdbStore !== null) {
      return this.rdbStore
    }
    if (this.initPromise !== null) {
      return this.initPromise
    }

    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1,
    }

    this.initPromise = relationalStore.getRdbStore(context, config).then(async (store) => {
      this.rdbStore = store
      // Create tables
      await store.executeSql(CREATE_FEEDS_TABLE)
      await store.executeSql(CREATE_FEED_ITEMS_TABLE)
      await store.executeSql(CREATE_BLOCKLIST_TABLE)
      await store.executeSql(CREATE_SEARCH_RESULTS_TABLE)
      // Create indexes
      await store.executeSql(CREATE_INDEX_FEED_ITEMS_FEED_ID)
      await store.executeSql(CREATE_INDEX_FEED_ITEMS_UNREAD)
      await store.executeSql(CREATE_INDEX_FEED_ITEMS_BOOKMARKED)
      await store.executeSql(CREATE_INDEX_FEED_ITEMS_PUBDATE)
      await store.executeSql(CREATE_INDEX_FEEDS_TAG)
      hilog.info(DOMAIN, TAG, 'Database initialized successfully')
      return store
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'Database init failed: %{public}s', err.message)
      this.initPromise = null
      throw err
    })

    return this.initPromise
  }

  getStore(): relationalStore.RdbStore {
    if (this.rdbStore === null) {
      throw new Error('Database not initialized. Call init() first.')
    }
    return this.rdbStore
  }

  async deleteStore(context: Context): Promise<void> {
    if (this.rdbStore !== null) {
      await relationalStore.deleteRdbStore(context, DB_NAME)
      this.rdbStore = null
      this.initPromise = null
    }
  }
}
