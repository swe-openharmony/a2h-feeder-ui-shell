// App-level state management for Feeder RSS Reader
// Initializes global AppStorage keys + seeds test data on first launch

import { FeedRepository } from '../repository/FeedRepository'
import { ArticleRepository } from '../repository/ArticleRepository'
import { SettingsRepository } from '../repository/SettingsRepository'
import { DatabaseHelper } from '../repository/DatabaseHelper'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'AppState'

export interface SeedArticleData {
  title: string
  snippet: string
  link: string
  pubDate: number
  htmlContent: string
  imageUrl: string
  author: string
  unread: boolean
  bookmarked: boolean
}

export class AppState {
  private static initialized: boolean = false

  static async init(context: Context): Promise<void> {
    if (AppState.initialized) {
      return
    }
    hilog.info(DOMAIN, TAG, 'AppState initializing...')

    // Initialize database
    const dbHelper = DatabaseHelper.getInstance()
    await dbHelper.init(context)

    // Initialize settings
    const settingsRepo = SettingsRepository.getInstance()
    await settingsRepo.init(context)
    settingsRepo.loadAllToAppStorage()

    // Set up global AppStorage keys
    AppStorage.setOrCreate('currentFeedId', 0)   // 0 = all feeds, -1 = saved, >0 = specific feed
    AppStorage.setOrCreate('currentTag', '')
    AppStorage.setOrCreate('currentFilter', 'Unread')
    AppStorage.setOrCreate('filterSaved', false)
    AppStorage.setOrCreate('filterRecentlyRead', false)
    AppStorage.setOrCreate('filterRead', false)
    AppStorage.setOrCreate('drawerOpen', false)
    AppStorage.setOrCreate('searchExpanded', false)
    AppStorage.setOrCreate('overflowVisible', false)
    AppStorage.setOrCreate('filterVisible', false)
    AppStorage.setOrCreate('syncInProgress', false)
    AppStorage.setOrCreate('feedDataVersion', 0)

    // Seed demo data (3 feeds + 7 articles) for initial app experience
    // This replaces the old seedDefaultData which only added an empty feed
    await AppState.seedDemoData()

    AppState.initialized = true
    AppStorage.setOrCreate('dbReady', true)
    hilog.info(DOMAIN, TAG, 'AppState initialized successfully')
  }

  private static async seedDefaultData(): Promise<void> {
    const feedRepo = FeedRepository.getInstance()
    const existingFeeds = await feedRepo.getAllFeeds()
    if (existingFeeds.length === 0) {
      // Seed the default Feeder News feed
      const feedId = await feedRepo.seedFeed(
        'https://news.nononsenseapps.com/index.atom',
        'Feeder News',
        ''
      )
      hilog.info(DOMAIN, TAG, 'Seeded default feed id=%{public}d', feedId)
    }
  }

  // Seed demo data: 3 feeds + 7 articles for initial app experience
  private static async seedDemoData(): Promise<void> {
    try {
      const feedRepo = FeedRepository.getInstance()
      const articleRepo = ArticleRepository.getInstance()

      // Seed only a genuinely empty install; relaunch must preserve user state.
      const existingFeeds = await feedRepo.getAllFeeds()
      const existingArticles = await articleRepo.getArticlesByFeed(0, true, false, false, false, 'DESC')
      if (existingFeeds.length > 0 || existingArticles.length > 0) {
        hilog.info(DOMAIN, TAG, 'Existing user data found, skipping fresh-install seed')
        return
      }

      // Seed 3 feeds with tags
      const feed1Id = await feedRepo.seedFeed('https://example.com/feed1.xml', 'Tech News', 'Technology')
      const feed2Id = await feedRepo.seedFeed('https://example.com/feed2.xml', 'Science Daily', 'Science')
      const feed3Id = await feedRepo.seedFeed('https://example.com/feed3.xml', 'World News', '')

      const now = Date.now()
      const hour = 3600000

      // Seed articles for feed 1 (Tech News)
      await articleRepo.seedArticle(feed1Id, 'AI breakthrough in language models',
        'Researchers announce major advances in natural language processing...', 'https://example.com/ai',
        now - hour, '<p>Researchers announce major advances in natural language processing that could transform how we interact with technology.</p><p><a href="#related-section">Jump to related section</a></p><div style="height: 1600px"><p>Public sample body separates the link from its destination so anchor navigation is observable.</p></div><h2 id="related-section">Related section</h2><p>Public sample content for the seeded article.</p>')
      await articleRepo.seedArticle(feed1Id, 'New smartphone features revealed',
        'Latest flagship phone includes revolutionary camera system...', 'https://example.com/phone',
        now - 2 * hour, '<p>Latest flagship phone includes revolutionary camera system and improved battery life.</p>')
      await articleRepo.seedArticle(feed1Id, 'Cloud computing trends for 2026',
        'Enterprise adoption of multi-cloud strategies accelerates...', 'https://example.com/cloud',
        now - 3 * hour, '<p>Enterprise adoption of multi-cloud strategies accelerates as organizations seek flexibility.</p>')
      await articleRepo.seedArticle(feed1Id, 'Saved AI field notes',
        'A public bookmarked article used to verify feed deletion cascade...', 'https://example.com/saved-ai',
        now - 3.5 * hour, '<p>Public saved sample for cross-feed deletion checks.</p>',
        '', '', '', true, true)

      // Seed articles for feed 2 (Science Daily)
      await articleRepo.seedArticle(feed2Id, 'Mars rover discovers water traces',
        'The latest data from the rover suggests ancient river beds...', 'https://example.com/mars',
        now - 4 * hour, '<p>The latest data from the rover suggests ancient river beds existed on Mars.</p>')
      await articleRepo.seedArticle(feed2Id, 'Climate change impact on oceans',
        'New study reveals accelerated ocean warming patterns...', 'https://example.com/ocean',
        now - 5 * hour, '<p>New study reveals accelerated ocean warming patterns affecting marine ecosystems.</p>',
        '', '', '', true, true) // bookmarked for saved articles test

      // Seed articles for feed 3 (World News)
      await articleRepo.seedArticle(feed3Id, 'Global trade agreements updated',
        'Major economies sign new trade framework...', 'https://example.com/trade',
        now - 6 * hour, '<p>Major economies sign new trade framework aimed at reducing barriers.</p>')
      await articleRepo.seedArticle(feed3Id, 'International space station anniversary',
        'Celebrating 30 years of continuous human presence in space...', 'https://example.com/iss',
        now - 7 * hour, '<p>Celebrating 30 years of continuous human presence in space.</p>')

      // Increment data version to trigger UI refresh
      AppStorage.setOrCreate('feedDataVersion', (AppStorage.get<number>('feedDataVersion') ?? 0) + 1)

      hilog.info(DOMAIN, TAG, 'Sample data seeded: 3 feeds, 8 articles')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Demo seed failed: %{public}s', JSON.stringify(err))
    }
  }

  static async seedTestData(feedUrl: string, feedTitle: string, tag: string,
                            articles: SeedArticleData[]): Promise<number> {
    const feedRepo = FeedRepository.getInstance()
    const articleRepo = ArticleRepository.getInstance()

    // Check if feed already exists
    const existingFeeds = await feedRepo.getAllFeeds()
    const existing = existingFeeds.find(f => f.url === feedUrl)
    let feedId: number
    if (existing) {
      feedId = existing.id
    } else {
      feedId = await feedRepo.seedFeed(feedUrl, feedTitle, tag)
    }

    // Seed articles
    for (const article of articles) {
      await articleRepo.seedArticle(
        feedId,
        article.title,
        article.snippet,
        article.link,
        article.pubDate,
        article.htmlContent,
        '',
        article.imageUrl ?? '',
        article.author ?? '',
        article.unread ?? true,
        article.bookmarked ?? false,
      )
    }

    // Increment data version to trigger UI refresh
    AppStorage.setOrCreate('feedDataVersion', (AppStorage.get<number>('feedDataVersion') ?? 0) + 1)

    return feedId
  }
}
