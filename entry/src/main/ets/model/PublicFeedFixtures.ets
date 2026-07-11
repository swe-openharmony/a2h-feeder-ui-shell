/**
 * Neutral offline documents available to feed-discovery implementations.
 *
 * These records model deterministic URL responses only. They do not update
 * repositories, create subscriptions, or drive any UI state.
 */
export class PublicOfflineFeedDocument {
  url: string
  contentType: string
  body: string

  constructor(url: string, contentType: string, body: string) {
    this.url = url
    this.contentType = contentType
    this.body = body
  }
}

export const PUBLIC_DISCOVERY_PAGE_URL: string =
  'https://example.com/fixture-feed.html'
export const PUBLIC_DISCOVERY_FEED_URL: string =
  'https://example.com/fixture-feed.xml'
export const PUBLIC_DISCOVERY_TITLE: string = 'Example Fixture Feed'
export const PUBLIC_UNAVAILABLE_FEED_URL: string =
  'https://example.invalid/unavailable-feed.xml'

const PUBLIC_DISCOVERY_HTML: string =
  '<!doctype html>\n' +
  '<html><head><title>Example Fixture Feed</title>\n' +
  '<link rel="alternate" type="application/rss+xml" ' +
  'title="Example Fixture Feed" href="https://example.com/fixture-feed.xml">\n' +
  '</head><body><h1>Example Fixture Feed</h1></body></html>\n'

const PUBLIC_DISCOVERY_RSS: string =
  '<?xml version="1.0" encoding="UTF-8"?>\n' +
  '<rss version="2.0"><channel>\n' +
  '<title>Example Fixture Feed</title>\n' +
  '<description>Deterministic public feed-discovery fixture</description>\n' +
  '<link>https://example.com/fixture-feed</link>\n' +
  '<item><title>Fixture article</title>' +
  '<link>https://example.com/fixture-article</link>' +
  '<guid>fixture-article</guid>' +
  '<description>Public offline fixture content.</description></item>\n' +
  '</channel></rss>\n'

export const PUBLIC_OFFLINE_FEED_DOCUMENTS: PublicOfflineFeedDocument[] = [
  new PublicOfflineFeedDocument(
    PUBLIC_DISCOVERY_PAGE_URL,
    'text/html; charset=utf-8',
    PUBLIC_DISCOVERY_HTML,
  ),
  new PublicOfflineFeedDocument(
    PUBLIC_DISCOVERY_FEED_URL,
    'application/rss+xml; charset=utf-8',
    PUBLIC_DISCOVERY_RSS,
  ),
]

export function findPublicOfflineFeedDocument(
  url: string,
): PublicOfflineFeedDocument | undefined {
  return PUBLIC_OFFLINE_FEED_DOCUMENTS.find(
    (document: PublicOfflineFeedDocument) => document.url === url,
  )
}
