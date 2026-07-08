// FeedList page - Main screen of Feeder RSS Reader
// UI skeleton, navigation, mock rendering preserved

import { router } from '@kit.ArkUI'
import { FeedRepository, FeedRow } from '../repository/FeedRepository'
import { ArticleRepository, ArticleRow } from '../repository/ArticleRepository'
import { SettingsRepository } from '../repository/SettingsRepository'
import { SyncService } from '../service/SyncService'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'FeedList'

@Entry
@Component
struct FeedList {
  @StorageLink('currentFeedTitle') currentFeedTitle: string = 'All Feeds'
  @StorageLink('currentFeedId') currentFeedId: number = 0
  @StorageLink('feedDataVersion') feedDataVersion: number = 0
  @StorageLink('syncInProgress') syncInProgress: boolean = false
  @StorageLink('drawerOpen') drawerOpen: boolean = false
  @State filterVisible: boolean = false
  @State overflowVisible: boolean = false
  @StorageLink('searchExpanded') searchExpanded: boolean = false
  @StorageLink('currentFilter') currentFilter: string = 'Unread'
  @StorageLink('filterSaved') filterSaved: boolean = false
  @StorageLink('filterRecentlyRead') filterRecentlyRead: boolean = false
  @StorageLink('filterRead') filterRead: boolean = false

  @State feeds: FeedRow[] = []
  @State articles: ArticleRow[] = []
  @State searchText: string = ''
  @State selectedDrawerIndex: number = 0
  @State expandedTags: Set<string> = new Set()
  @State tagsWithFeeds: Map<string, FeedRow[]> = new Map()
  @State tagUnreadCounts: Map<string, number> = new Map()
  @State untaggedFeeds: FeedRow[] = []
  @State totalUnread: number = 0
  @State savedCount: number = 0
  @State isRefreshing: boolean = false
  @State deleteDialogVisible: boolean = false
  @State editFeedDialogVisible: boolean = false
  @State selectedFeedIdsForDelete: Set<number> = new Set()
  @State selectedFeedIdForEdit: number = 0

  async aboutToAppear() {
    // Wait for database to be ready before loading data
    while (!AppStorage.get<boolean>('dbReady')) {
      await new Promise<void>(resolve => setTimeout(resolve, 100))
    }
    await this.loadData()
  }

  async loadData() {
    try {
      const feedRepo = FeedRepository.getInstance()
      const articleRepo = ArticleRepository.getInstance()

      // Load feeds
      const allFeeds = await feedRepo.getAllFeeds()
      this.feeds = allFeeds

      // Group feeds by tag
      const tagMap = new Map<string, FeedRow[]>()
      const untagged: FeedRow[] = []
      for (const feed of allFeeds) {
        if (feed.tag.length > 0) {
          if (!tagMap.has(feed.tag)) {
            tagMap.set(feed.tag, [])
          }
          tagMap.get(feed.tag)!.push(feed)
        } else {
          untagged.push(feed)
        }
      }
      this.tagsWithFeeds = tagMap
      this.untaggedFeeds = untagged

      // Load unread counts per tag
      const tagUnreadMap = new Map<string, number>()
      for (const tag of Array.from(tagMap.keys())) {
        const count = await feedRepo.getUnreadCountByTag(tag)
        tagUnreadMap.set(tag, count)
      }
      this.tagUnreadCounts = tagUnreadMap

      // Load unread counts per feed
      this.totalUnread = await feedRepo.getTotalUnreadCount()

      // Load articles based on current filter
      await this.loadArticles()

      hilog.info(DOMAIN, TAG, 'Data loaded: %{public}d feeds, %{public}d articles',
        allFeeds.length, this.articles.length)
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Load data failed: %{public}s', JSON.stringify(err))
    }
  }

  async loadArticles() {
    try {
      const articleRepo = ArticleRepository.getInstance()
      const settingsRepo = SettingsRepository.getInstance()
      const sortOrder = settingsRepo.getString('sort_order', 'Newest first') === 'Newest first' ? 'DESC' : 'ASC'

      if (this.currentFeedId === -1) {
        // Saved articles view
        this.articles = await articleRepo.getSavedArticles()
      } else if (this.searchText.length > 0) {
        // Search results
        this.articles = await articleRepo.searchArticles(this.searchText)
      } else {
        // Filtered feed view
        this.articles = await articleRepo.getArticlesByFeed(
          this.currentFeedId,
          this.currentFilter === 'Unread' && !this.filterSaved && !this.filterRead,
          this.filterSaved,
          this.filterRead,
          this.filterRecentlyRead,
          sortOrder
        )
      }

      // Count saved articles
      this.savedCount = (await articleRepo.getSavedArticles()).length
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Load articles failed: %{public}s', JSON.stringify(err))
    }
  }

  build() {
    Column() {
      // SideBarContainer as base layer
      SideBarContainer(SideBarContainerType.Overlay) {
        // === Navigation Drawer Content ===
        this.NavigationDrawer()

        // === Main Content ===
        Stack() {
          Column() {
            // Top App Bar
            if (this.searchExpanded) {
              this.SearchBar()
            } else {
              this.TopAppBar()
            }

            // Content area
            if (this.articles.length === 0) {
              this.EmptyState()
            } else {
              this.ArticleList()
            }

            // FAB
            this.FabButton()
          }
          .width('100%')
          .height('100%')

          // === Overlays rendered inside Stack within SideBarContainer ===
          if (this.filterVisible) {
            this.FilterDropdown()
          }

          if (this.overflowVisible) {
            this.OverflowMenu()
          }

          // Delete feed dialog
          if (this.deleteDialogVisible) {
            this.DeleteFeedDialog()
          }

          // Edit feed selection dialog
          if (this.editFeedDialogVisible) {
            this.EditFeedSelectionDialog()
          }
        }
        .width('100%')
        .height('100%')
      }
      .sideBarWidth(315)
      .showSideBar(this.drawerOpen)
      .onChange((show: boolean) => {
        this.drawerOpen = show
        if (show) {
          this.filterVisible = false
          this.overflowVisible = false
        }
      })
      .autoHide(true)
      .controlButton(null)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  // === Top App Bar ===
  @Builder
  TopAppBar() {
    Row() {
      // Hamburger menu / Navigation drawer toggle
      Row() {
        Image($r('app.media.ic_menu'))
          .width(24)
          .height(24)
          .fillColor('#ffffff')
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .borderRadius(24)
      .key('navigation_drawer_button')
      .onClick(() => {
        this.drawerOpen = !this.drawerOpen
        this.filterVisible = false
        this.overflowVisible = false
      })

      // Title
      Text(this.currentFeedTitle)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#ffffff')
        .margin({ left: 8 })
        .layoutWeight(1)

      // Search button
      Row() {
        Image($r('app.media.ic_search'))
          .width(24)
          .height(24)
          .fillColor('#ffffff')
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .borderRadius(24)
      .key('search_button')
      .onClick(() => {
        this.searchExpanded = true
        this.filterVisible = false
        this.overflowVisible = false
      })

      // Filter button (only when not on saved articles)
      if (this.currentFeedId !== -1) {
        Row() {
          Image($r('app.media.ic_filter'))
            .width(24)
            .height(24)
            .fillColor('#ffffff')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .borderRadius(24)
        .key('filter_button')
        .onClick(() => {
          this.filterVisible = !this.filterVisible
          this.overflowVisible = false
        })
      }

      // Overflow menu button
      Row() {
        Image($r('app.media.ic_more_vert'))
          .width(24)
          .height(24)
          .fillColor('#ffffff')
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .borderRadius(24)
      .key('overflow_menu_button')
      .onClick(() => {
        this.overflowVisible = !this.overflowVisible
        this.filterVisible = false
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 4, right: 4 })
    .backgroundColor($r('app.color.primary'))
    .alignItems(VerticalAlign.Center)
  }

  // === Search Bar ===
  @Builder
  SearchBar() {
    Row() {
      // Back arrow
      Image($r('app.media.ic_arrow_back'))
        .width(24)
        .height(24)
        .fillColor('#ffffff')
        .onClick(() => {
          this.searchExpanded = false
          this.searchText = ''
          this.loadArticles()
        })

      // Search input
      TextInput({ text: this.searchText, placeholder: 'Search feeds' })
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#1fffffff')
        .fontColor('#ffffff')
        .placeholderColor('#99ffffff')
        .borderRadius(8)
        .key('search_input')
        .onChange((value: string) => {
          this.searchText = value
          this.loadArticles()
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.primary'))
    .alignItems(VerticalAlign.Center)
  }

  // === Empty State ===
  @Builder
  EmptyState() {
    Column() {
      Text('Nothing to read here')
        .fontSize(18)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .margin({ left: 28, right: 28 })

      // "Add feed" link (matching Android style)
      Text('Add feed')
        .fontSize(16)
        .fontColor($r('app.color.primary'))
        .decoration({ type: TextDecorationType.Underline, color: $r('app.color.primary') })
        .margin({ top: 32 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/AddFeed' })
        })

      // "Dismiss" link (matching Android style)
      Text('Dismiss')
        .fontSize(16)
        .fontColor($r('app.color.primary'))
        .decoration({ type: TextDecorationType.Underline, color: $r('app.color.primary') })
        .margin({ top: 16 })
        .onClick(() => {
          this.drawerOpen = true
          this.filterVisible = false
          this.overflowVisible = false
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // === Article List ===
  @Builder
  ArticleList() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      List() {
        ForEach(this.articles, (article: ArticleRow) => {
          ListItem() {
            this.ArticleRow(article)
          }
          .swipeAction({ end: this.SwipeActionItem(article) })
        }, (article: ArticleRow) => `${article.id}|${article.unread ? 1 : 0}|${article.bookmarked ? 1 : 0}`)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: '#e0e0e0' })
    }
    .onRefreshing(async () => {
      this.isRefreshing = false
    })
  }

  @Builder
  ArticleRow(article: ArticleRow) {
    Row() {
      Column() {
        Text(article.title)
          .fontSize(16)
          .fontWeight(article.unread ? FontWeight.Medium : FontWeight.Normal)
          .fontColor(article.unread ? '#212121' : '#999999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(article.plainSnippet)
          .fontSize(14)
          .fontColor('#757575')
          .margin({ top: 4 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(article.feedTitle)
            .fontSize(12)
            .fontColor('#9e9e9e')

          Text('·')
            .fontSize(12)
            .fontColor('#9e9e9e')
            .margin({ left: 6, right: 6 })

          Text(this.formatDate(article.pubDate))
            .fontSize(12)
            .fontColor('#9e9e9e')

          if (article.bookmarked) {
            Text('★')
              .fontSize(12)
              .fontColor($r('app.color.primary'))
              .margin({ left: 6 })
          }
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // Thumbnail
      if (article.imageUrl.length > 0) {
        Image(article.imageUrl)
          .width(56)
          .height(56)
          .borderRadius(4)
          .margin({ left: 12 })
          .objectFit(ImageFit.Cover)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      // const articleRepo = ArticleRepository.getInstance()
      // articleRepo.markRead(article.id)
      router.pushUrl({
        url: 'pages/ArticleReader',
        params: { articleId: article.id }
      })
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction(() => {
          // no-op: long press disabled
        })
    )
  }

  @Builder
  SwipeActionItem(article: ArticleRow) {
    Row() {
      Button(article.unread ? 'Mark read' : 'Mark unread')
        .fontSize(12)
        .fontColor('#ffffff')
        .backgroundColor($r('app.color.primary'))
        .borderRadius(4)
        .height(40)
        .onClick(async () => {
          // no-op: toggle read status disabled
        })
    }
    .padding({ right: 16 })
  }

  // === Navigation Drawer ===
  @Builder
  NavigationDrawer() {
    Column() {
      // "All feeds" row
      this.DrawerRow('All Feeds', 0, this.totalUnread)

      // "Saved articles" row
      this.DrawerRow('Saved Articles', 1, this.savedCount)

      Divider().color('#e0e0e0').margin({ top: 4, bottom: 4 })

      // Flat feed list (matching Android's simple drawer)
      List() {
        ForEach(Array.from(this.tagsWithFeeds.keys()), (tag: string) => {
          ListItem() {
            Column() {
              // Tag header row
              Row() {
                Text(tag)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#212121')
                  .layoutWeight(1)

                // Unread count for tag
                Text((this.tagUnreadCounts.get(tag) ?? 0).toString())
                  .fontSize(12)
                  .fontColor($r('app.color.primary'))
                  .margin({ right: 8 })

                // Expand/collapse arrow
                Image($r('app.media.ic_arrow_right'))
                  .width(16)
                  .height(16)
                  .fillColor('#757575')
                  .rotate({ angle: this.expandedTags.has(tag) ? 90 : 0 })
                  .key('tag_expand_arrow')
              }
              .width('100%')
              .height(48)
              .padding({ left: 16, right: 16 })
              .borderRadius(8)
              .onClick(() => {
                if (this.expandedTags.has(tag)) {
                  this.expandedTags.delete(tag)
                } else {
                  this.expandedTags.add(tag)
                }
                // Force re-render
                this.expandedTags = new Set(this.expandedTags)
              })

              // Child feeds (if expanded)
              if (this.expandedTags.has(tag)) {
                ForEach(this.tagsWithFeeds.get(tag) ?? [], (feed: FeedRow) => {
                  this.DrawerFeedRow(feed)
                }, (feed: FeedRow) => feed.id.toString())
              }
            }
          }
        }, (tag: string) => tag)

        // Untagged feeds
        ForEach(this.untaggedFeeds, (feed: FeedRow) => {
          ListItem() {
            this.DrawerFeedRow(feed)
          }
        }, (feed: FeedRow) => feed.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  @Builder
  DrawerRow(title: string, index: number, unreadCount: number) {
    Row() {
      Text(title)
        .fontSize(14)
        .fontWeight(this.selectedDrawerIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.selectedDrawerIndex === index ? $r('app.color.primary') : '#212121')
        .layoutWeight(1)

      if (unreadCount > 0) {
        Text(unreadCount.toString())
          .fontSize(12)
          .fontColor($r('app.color.primary'))
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.selectedDrawerIndex === index ? '#e8f5e9' : Color.Transparent)
    .borderRadius(8)
    .onClick(() => {
      this.selectedDrawerIndex = index
      this.currentFeedTitle = title
      if (index === 0) {
        this.currentFeedId = 0
        AppStorage.setOrCreate('currentFeedId', 0)
      } else if (index === 1) {
        this.currentFeedId = -1
        AppStorage.setOrCreate('currentFeedId', -1)
      }
      this.drawerOpen = false
      this.loadArticles()
    })
  }

  @Builder
  DrawerFeedRow(feed: FeedRow) {
    Row() {
      Text(feed.title)
        .fontSize(14)
        .fontColor('#212121')
        .layoutWeight(1)

      if (feed.id === this.currentFeedId) {
        // Highlight current feed
        Text('•')
          .fontSize(16)
          .fontColor($r('app.color.primary'))
          .margin({ right: 8 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 32, right: 16 })
    .borderRadius(8)
    .onClick(async () => {
      this.currentFeedId = feed.id
      AppStorage.setOrCreate('currentFeedId', feed.id)
      this.currentFeedTitle = feed.title
      this.selectedDrawerIndex = -1 // Deselect All/Saved
      this.drawerOpen = false
      await this.loadArticles()
    })
  }

  // === Filter Dropdown ===
  @Builder
  FilterDropdown() {
    // Full-screen overlay to capture taps and render above SideBarContainer
    Column() {
      // Semi-transparent backdrop - click to dismiss
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#33000000')
        .onClick(() => {
          this.filterVisible = false
        })

      // Filter panel positioned near the filter button
      Column() {
        this.FilterOption('Unread', this.currentFilter === 'Unread')
        this.FilterOption('Saved', this.filterSaved)
        this.FilterOption('Recently Read', this.filterRecentlyRead)
        this.FilterOption('Read', this.filterRead)
      }
      .width(220)
      .backgroundColor('#ffffff')
      .borderRadius(8)
      .shadow({ radius: 8, color: '#1a000000', offsetY: 2 })
      .position({ x: '45%', y: 56 })
    }
    .width('100%')
    .height('100%')
    .zIndex(200)
  }

  @Builder
  FilterOption(label: string, isActive: boolean) {
    Row() {
      Checkbox()
        .select(isActive)
        .selectedColor($r('app.color.primary'))
        .width(20)
        .height(20)
        .margin({ right: 12 })

      Text(label)
        .fontSize(16)
        .fontColor(isActive ? $r('app.color.primary') : '#212121')
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(async () => {
      if (label === 'Unread') {
        this.currentFilter = 'Unread'
        this.filterSaved = false
        this.filterRecentlyRead = false
        this.filterRead = false
        AppStorage.setOrCreate('currentFilter', 'Unread')
        AppStorage.setOrCreate('filterSaved', false)
        AppStorage.setOrCreate('filterRecentlyRead', false)
        AppStorage.setOrCreate('filterRead', false)
      } else if (label === 'Saved') {
        this.filterSaved = !this.filterSaved
        AppStorage.setOrCreate('filterSaved', this.filterSaved)
      } else if (label === 'Recently Read') {
        this.filterRecentlyRead = !this.filterRecentlyRead
        AppStorage.setOrCreate('filterRecentlyRead', this.filterRecentlyRead)
      } else if (label === 'Read') {
        this.filterRead = !this.filterRead
        AppStorage.setOrCreate('filterRead', this.filterRead)
      }
      this.filterVisible = false
      await this.loadArticles()
    })
  }

  // === Overflow Menu ===
  @Builder
  OverflowMenu() {
    Column() {
      // Semi-transparent backdrop - click to dismiss
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#33000000')
        .onClick(() => {
          this.overflowVisible = false
        })

      // Menu panel
      Scroll() {
        Column() {
        this.OverflowItem('Mark all as read', async () => {
          this.overflowVisible = false
          // no-op: mark all read disabled
        })

        this.OverflowItem('Sync current feed', async () => {
          this.overflowVisible = false
          // no-op: sync disabled
        })

        this.OverflowItem('Add feed', () => {
          this.overflowVisible = false
          router.pushUrl({ url: 'pages/AddFeed' })
        })

        this.OverflowItem('Edit feed', () => {
          this.overflowVisible = false
          if (this.feeds.length === 1) {
            // Single feed: navigate directly
            router.pushUrl({ url: 'pages/EditFeed', params: { feedId: this.feeds[0].id } })
          } else if (this.feeds.length > 1) {
            // Multiple feeds: show selection dialog
            this.editFeedDialogVisible = true
          }
        })

        this.OverflowItem('Delete feed', () => {
          this.overflowVisible = false
          // no-op: delete feed disabled
        })

        this.OverflowItem('Settings', () => {
          this.overflowVisible = false
          router.pushUrl({ url: 'pages/Settings' })
        })
      }
      .width(260)
    }
    .scrollable(ScrollDirection.Vertical)
    .width(260)
    .constraintSize({ maxHeight: '70%' })
    .backgroundColor('#ffffff')
    .borderRadius(8)
    .shadow({ radius: 8, color: '#1a000000', offsetY: 2 })
    .position({ x: '78%', y: 56 })
    }
    .width('100%')
    .height('100%')
    .zIndex(200)
  }

  @Builder
  OverflowItem(label: string, action: () => void) {
    Row() {
      if (label === 'Sync current feed') {
        Image($r('app.media.ic_stat_sync'))
          .width(20)
          .height(20)
          .fillColor('#757575')
          .margin({ right: 16 })
      }

      Text(label)
        .fontSize(16)
        .fontColor('#212121')
        .layoutWeight(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(action)
  }

  // === FAB ===
  @Builder
  FabButton() {
    if (this.articles.length > 0) {
      Row() {
        Image($r('app.media.ic_check'))
          .width(24)
          .height(24)
          .fillColor('#ffffff')
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor($r('app.color.primary'))
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 8, color: '#33000000', offsetY: 4 })
      .position({ x: '85%', y: '90%' })
      .key('fab_mark_read')
      .onClick(async () => {
        // no-op: FAB mark all read disabled
      })
    }
  }

  // === Delete Feed Dialog ===
  @Builder
  DeleteFeedDialog() {
    Column() {
      Text('Delete feed')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      // List of feeds with checkboxes
      ForEach(this.feeds, (feed: FeedRow) => {
        Row() {
          Checkbox()
            .select(this.selectedFeedIdsForDelete.has(feed.id))
            .onChange((checked: boolean) => {
              if (checked) {
                this.selectedFeedIdsForDelete.add(feed.id)
              } else {
                this.selectedFeedIdsForDelete.delete(feed.id)
              }
              this.selectedFeedIdsForDelete = new Set(this.selectedFeedIdsForDelete)
            })
            .margin({ right: 12 })

          Text(feed.title)
            .fontSize(16)
            .fontColor('#212121')
            .layoutWeight(1)
        }
        .width('100%')
        .height(48)
        .padding({ left: 8, right: 8 })
      }, (feed: FeedRow) => feed.id.toString())

      Row() {
        Button('Cancel')
          .fontSize(14)
          .fontColor('#757575')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onClick(() => {
            this.deleteDialogVisible = false
          })

        Button('Delete')
          .fontSize(14)
          .fontColor('#d32f2f')
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .enabled(this.selectedFeedIdsForDelete.size > 0)
          .onClick(async () => {
            // no-op: delete disabled
            this.deleteDialogVisible = false
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 16 })
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#ffffff')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#33000000' })
  }

  // === Edit Feed Selection Dialog ===
  @Builder
  EditFeedSelectionDialog() {
    Column() {
      Text('Edit feed')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      ForEach(this.feeds, (feed: FeedRow) => {
        Row() {
          Text(feed.title)
            .fontSize(16)
            .fontColor('#212121')
            .layoutWeight(1)
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .borderRadius(8)
        .onClick(() => {
          this.editFeedDialogVisible = false
          router.pushUrl({ url: 'pages/EditFeed', params: { feedId: feed.id } })
        })
      }, (feed: FeedRow) => feed.id.toString())

      Button('Cancel')
        .fontSize(14)
        .fontColor('#757575')
        .backgroundColor(Color.Transparent)
        .margin({ top: 8 })
        .onClick(() => {
          this.editFeedDialogVisible = false
        })
    }
    .width('80%')
    .padding(24)
    .backgroundColor('#ffffff')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#33000000' })
  }

  // === Context Menu (triggered by long-press) ===
  private showContextMenu(article: ArticleRow) {
    // no-op: context menu disabled
  }

  // === Helpers ===
  private formatDate(timestamp: number): string {
    if (timestamp === 0) return ''
    const date = new Date(timestamp)
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`
  }

}
