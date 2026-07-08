import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppState } from '../common/AppState';
import { FeedRepository } from '../repository/FeedRepository';
import { ArticleRepository } from '../repository/ArticleRepository';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // Check for test seed parameter
    const seedData = want.parameters?.['seed_test_data'] as string;
    const clearData = want.parameters?.['clear_data'] as string;

    // Initialize the app state (database, settings, etc.)
    AppState.init(this.context).then(async () => {
      hilog.info(DOMAIN, 'testTag', 'AppState initialized successfully');

      if (clearData === 'true') {
        hilog.info(DOMAIN, 'testTag', 'Clearing test data');
        // Clear data handled via force-stop + fresh launch
      }

      // Always seed test data on first launch (or if data is missing)
      // seed_test_data=true forces re-seed even if data exists
      if (seedData === 'true') {
        hilog.info(DOMAIN, 'testTag', 'Forced re-seeding test data');
        await this.seedTestData(true);
      } else {
        // Auto-seed on first launch if no data exists
        await this.seedTestData(false);
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'AppState init failed: %{public}s', err.message);
    });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  // Test-injectable: seed sample data for testing preconditions
  // force=true: always re-seed; force=false: only seed if no data exists
  private async seedTestData(force: boolean = false): Promise<void> {
    try {
      const feedRepo = FeedRepository.getInstance();
      const articleRepo = ArticleRepository.getInstance();

      // Check if test data already exists with unread articles
      const existingFeeds = await feedRepo.getAllFeeds()
      const existingArticles = await articleRepo.getArticlesByFeed(0, true, false, false, false, 'DESC')
      if (!force && existingFeeds.length >= 3 && existingArticles.length >= 5) {
        hilog.info(DOMAIN, 'testTag', 'Test data already exists with unread articles, skipping seed');
        return;
      }

      // If feeds exist but no unread articles (tests marked them read), reset all to unread
      if (!force && existingFeeds.length >= 3 && existingArticles.length === 0) {
        hilog.info(DOMAIN, 'testTag', 'Feeds exist but no unread articles, resetting to unread');
        await articleRepo.resetAllToUnread();
        AppStorage.setOrCreate('feedDataVersion', (AppStorage.get<number>('feedDataVersion') ?? 0) + 1)
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
        now - hour, '<p>Researchers announce major advances in natural language processing that could transform how we interact with technology.</p>')
      await articleRepo.seedArticle(feed1Id, 'New smartphone features revealed',
        'Latest flagship phone includes revolutionary camera system...', 'https://example.com/phone',
        now - 2 * hour, '<p>Latest flagship phone includes revolutionary camera system and improved battery life.</p>')
      await articleRepo.seedArticle(feed1Id, 'Cloud computing trends for 2026',
        'Enterprise adoption of multi-cloud strategies accelerates...', 'https://example.com/cloud',
        now - 3 * hour, '<p>Enterprise adoption of multi-cloud strategies accelerates as organizations seek flexibility.</p>')

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

      hilog.info(DOMAIN, 'testTag', 'Test data seeded: 3 feeds, 7 articles')
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Seed test data failed: %{public}s', JSON.stringify(err))
    }
  }
}
