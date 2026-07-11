import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppState } from '../common/AppState';
import { FeedRepository } from '../repository/FeedRepository';
import { ArticleRepository } from '../repository/ArticleRepository';

const DOMAIN = 0x0000;
const DEFAULT_PAGE = 'pages/Index';
const PAGE_BY_SURFACE: Record<string, string> = {
  'feed_list': 'pages/Index',
  'add_feed': 'pages/AddFeed',
  'article_reader': 'pages/Index',
  'settings': 'pages/Settings',
  'text_settings': 'pages/TextSettings',
  'device_sync': 'pages/DeviceSync'
};
const PUBLIC_FIXTURES: Record<string, boolean> = {
  'sample_feeds': true,
  'feed_discovery': true
};

export default class EntryAbility extends UIAbility {
  private launchPage: string = DEFAULT_PAGE;
  private fixture: string = '';
  private windowStage: window.WindowStage | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    this.resolveLaunchContext(want);

    // Initialize the app state (database, settings, etc.)
    AppState.init(this.context).then(async () => {
      hilog.info(DOMAIN, 'testTag', 'AppState initialized successfully');

      if (this.fixture === 'sample_feeds') {
        hilog.info(DOMAIN, 'testTag', 'Loading public sample_feeds fixture');
        await this.seedTestData(false);
      } else {
        // Auto-seed on first launch if no data exists
        await this.seedTestData(false);
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'AppState init failed: %{public}s', err.message);
    });
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.resolveLaunchContext(want);
    if (this.windowStage) {
      this.loadPage(this.launchPage);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    this.windowStage = windowStage;
    this.loadPage(this.launchPage);
  }

  private loadPage(page: string): void {
    if (!this.windowStage) {
      return;
    }
    this.windowStage.loadContent(page, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    this.windowStage = undefined;
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  private resolveLaunchContext(want: Want): void {
    const requestedSurface = want.parameters?.['benchmark_surface'] as string;
    const requestedFixture = want.parameters?.['benchmark_fixture'] as string;
    this.launchPage = requestedSurface && PAGE_BY_SURFACE[requestedSurface] ?
      PAGE_BY_SURFACE[requestedSurface] : DEFAULT_PAGE;
    this.fixture = requestedFixture && PUBLIC_FIXTURES[requestedFixture] ? requestedFixture : '';
  }

  // Test-injectable: seed sample data for testing preconditions
  // force=true: always re-seed; force=false: only seed if no data exists
  private async seedTestData(force: boolean = false): Promise<void> {
    try {
      const feedRepo = FeedRepository.getInstance();
      const articleRepo = ArticleRepository.getInstance();

      // Fresh-install sample data must not repair user mutations on relaunch.
      const existingFeeds = await feedRepo.getAllFeeds()
      const existingArticles = await articleRepo.getArticlesByFeed(0, true, false, false, false, 'DESC')
      if (!force && (existingFeeds.length > 0 || existingArticles.length > 0)) {
        hilog.info(DOMAIN, 'testTag', 'Existing user data found, skipping fresh-install seed');
        return;
      }

      // Seed 3 feeds with tags
      const feed1Id = await feedRepo.seedFeed(
        'https://example.com/feed1.xml',
        'Tech News',
        'Technology'
      );
      const feed2Id = await feedRepo.seedFeed(
        'https://example.com/feed2.xml',
        'Science Daily',
        'Science'
      );
      const feed3Id = await feedRepo.seedFeed(
        'https://example.com/feed3.xml',
        'World News',
        ''
      );

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

      hilog.info(DOMAIN, 'testTag', 'Sample data seeded: 3 feeds, 8 articles')
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Seed test data failed: %{public}s', JSON.stringify(err))
    }
  }
}
