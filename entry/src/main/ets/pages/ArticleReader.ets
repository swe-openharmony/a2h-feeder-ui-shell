// ArticleReader page - Reading view for RSS articles
// UI skeleton and navigation preserved

import { router } from '@kit.ArkUI'
import { webview } from '@kit.ArkWeb'
import { ArticleRepository, ArticleRow } from '../repository/ArticleRepository'
import { FeedRepository } from '../repository/FeedRepository'
import { SyncService } from '../service/SyncService'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'ArticleReader'

@Entry
@Component
struct ArticleReader {
  @State article: ArticleRow | null = null
  @State articleId: number = -1
  @State feedTitle: string = ''
  @State overflowVisible: boolean = false
  @State fullTextMode: boolean = false
  @State fetchingFullText: boolean = false
  @State fullTextError: string = ''
  @State isBookmarked: boolean = false
  @State isRead: boolean = false
  @State htmlContent: string = ''
  private webviewController: webview.WebviewController = new webview.WebviewController()
  private scrollSaveTimer: number = -1

  async aboutToAppear() {
    // Get article ID from router params
    const params = router.getParams() as Record<string, number>
    if (params && params['articleId'] !== undefined) {
      this.articleId = params['articleId']
    }

    if (this.articleId >= 0) {
      await this.loadArticle()
    }
  }

  async loadArticle() {
    try {
      const articleRepo = ArticleRepository.getInstance()
      const article = await articleRepo.getArticleById(this.articleId)
      if (article !== null) {
        this.article = article
        this.isBookmarked = article.bookmarked
        this.isRead = article.unread
        this.feedTitle = article.feedTitle
        this.fullTextMode = article.fullTextDownloaded
        this.htmlContent = this.buildArticleHtml(article)

        // await articleRepo.markRead(article.id)
        // this.isRead = true
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Load article failed: %{public}s', JSON.stringify(err))
    }
  }

  build() {
    Column() {
      // Top App Bar
      Row() {
        Row() {
          Image($r('app.media.ic_arrow_back'))
            .width(24)
            .height(24)
            .fillColor('#ffffff')
        }
        .width(48)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .borderRadius(24)
        .key('reader_back_button')
        .onClick(() => {
          router.back()
        })

        // Title
        Text(this.article?.title ?? 'Article')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#ffffff')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 4 })

        Row() {
          Text('Full')
            .fontSize(12)
            .fontColor('#ffffff')
        }
        .height(32)
        .padding({ left: 12, right: 12 })
        .borderRadius(16)
        .backgroundColor(this.fullTextMode ? '#1fffffff' : Color.Transparent)
        .border({ width: 1, color: '#99ffffff', radius: 16 })
        .justifyContent(FlexAlign.Center)
        .key('full_text_toggle')
        .onClick(async () => {
          // no-op: full-text toggle disabled
        })

        Row() {
          Image($r('app.media.notification_open_in_browser'))
            .width(20)
            .height(20)
            .fillColor('#ffffff')
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .borderRadius(22)
        .onClick(() => {
          // no-op: open in browser disabled
        })

        // Overflow menu
        Row() {
          Image($r('app.media.ic_more_vert'))
            .width(24)
            .height(24)
            .fillColor('#ffffff')
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .borderRadius(22)
        .key('article_overflow_button')
        .onClick(() => {
          this.overflowVisible = !this.overflowVisible
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 4, right: 4 })
      .backgroundColor($r('app.color.primary'))
      .alignItems(VerticalAlign.Center)

      // Article content area
      Stack() {

        // Web component for article content
        if (this.htmlContent.length > 0) {
          Web({ src: `data:text/html;charset=utf-8,${encodeURIComponent(this.htmlContent)}`,
               controller: this.webviewController })
            .width('100%')
            .height('100%')
            .backgroundColor('#ffffff')
            .onPageEnd(() => {
            })
            .onOverrideUrlLoading((webResourceRequest: WebResourceRequest) => {
              // no-op: link interception disabled, allow navigation
              return false
            })
            .domStorageAccess(true)
            .javaScriptAccess(true)
        } else {
          // Fallback: plain text view
          Scroll() {
            Column() {
              Text(this.article?.title ?? '')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#212121')
                .width('100%')

              Row() {
                Text(this.feedTitle)
                  .fontSize(13)
                  .fontColor('#757575')

                Text(' · ')
                  .fontSize(13)
                  .fontColor('#9e9e9e')

                Text(this.formatDate(this.article?.pubDate ?? 0))
                  .fontSize(13)
                  .fontColor('#757575')
              }
              .margin({ top: 8 })

              Text(this.article?.plainSnippet ?? '')
                .fontSize(16)
                .fontColor('#424242')
                .lineHeight(24)
                .margin({ top: 16 })
                .width('100%')
            }
            .padding(16)
          }
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)

      // Overflow menu
      if (this.overflowVisible) {
        this.ArticleOverflowMenu()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }

  @Builder
  ArticleOverflowMenu() {
    Column() {
      // Open in browser (= Show original)
      this.OverflowMenuItem('Open in browser', () => {
        this.overflowVisible = false
        // no-op: open in browser disabled
      })

      // Share
      this.OverflowMenuItem('Share', () => {
        this.overflowVisible = false
        // no-op: share disabled
      })

      // Mark as unread / Mark as read
      this.OverflowMenuItem(this.isRead ? 'Mark as unread' : 'Mark as read', async () => {
        this.overflowVisible = false
        // no-op: mark read/unread disabled
      })
    }
    .width(240)
    .backgroundColor('#ffffff')
    .borderRadius(8)
    .shadow({ radius: 8, color: '#1a000000', offsetY: 2 })
    .position({ x: '50%', y: 56 })
    .zIndex(10)
  }

  @Builder
  OverflowMenuItem(label: string, action: () => void) {
    Row() {
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

  private buildArticleHtml(article: ArticleRow): string {
    const pubDate = this.formatDate(article.pubDate)
    let content = article.htmlContent
    if (content.length === 0) {
      content = `<p>${article.plainSnippet}</p>`
    }
    return `<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 16px; line-height: 1.6; color: #212121; margin: 0; padding: 16px;
    word-wrap: break-word; overflow-wrap: break-word; }
  img { max-width: 100%; height: auto; border-radius: 4px; margin: 8px 0; }
  a { color: #0b8043; text-decoration: none; }
  a:hover { text-decoration: underline; }
  pre { background: #f5f5f5; padding: 12px; border-radius: 4px; overflow-x: auto; }
  blockquote { border-left: 3px solid #0b8043; margin: 8px 0; padding: 8px 16px; color: #757575; }
  .article-title { font-size: 22px; font-weight: bold; margin-bottom: 8px; }
  .article-meta { font-size: 13px; color: #757575; margin-bottom: 16px; }
  .article-meta a { color: #0b8043; text-decoration: none; cursor: pointer; }
</style>
</head><body>
<div class="article-title">${article.title}</div>
<div class="article-meta">
  <a href="feed://${article.feedId}" id="feedTitle">${article.feedTitle}</a> · ${pubDate}
</div>
<div class="article-content">${content}</div>
</body></html>`
  }

  private buildFullArticleHtml(fullHtml: string): string {
    return `<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 16px; line-height: 1.6; color: #212121; margin: 0; padding: 16px;
    word-wrap: break-word; overflow-wrap: break-word; }
  img { max-width: 100%; height: auto; border-radius: 4px; margin: 8px 0; }
  a { color: #0b8043; text-decoration: none; }
  a:hover { text-decoration: underline; }
  pre { background: #f5f5f5; padding: 12px; border-radius: 4px; overflow-x: auto; }
  blockquote { border-left: 3px solid #0b8043; margin: 8px 0; padding: 8px 16px; color: #757575; }
</style>
</head><body>
${fullHtml}
</body></html>`
  }

  private formatDate(timestamp: number): string {
    if (timestamp === 0) return ''
    const date = new Date(timestamp)
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`
  }
}
