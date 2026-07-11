// RssParser.ets -- String-based RSS 2.0 and Atom parser

import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'RssParser'

export interface ParsedFeedItem {
  title: string
  plainTitle: string
  plainSnippet: string
  link: string
  guid: string
  pubDate: number
  author: string
  imageUrl: string
  enclosureLink: string
  enclosureType: string
  htmlContent: string
}

export interface ParsedFeedMeta {
  title: string
  description: string
  link: string
  feedUrl: string
}

export interface DiscoveryResult {
  feedUrl: string
  title: string
  description: string
}

export function parseRssFeed(xmlContent: string): ParsedFeedItem[] {
  const items: ParsedFeedItem[] = []
  try {
    // Simple XML string-based parsing for RSS 2.0 and Atom feeds
    parseRssXml(xmlContent, items)
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'RSS parse error: %{public}s', JSON.stringify(err))
  }
  return items
}

function parseRssXml(xmlContent: string, items: ParsedFeedItem[]): void {
  // Simple XML parser for RSS 2.0 and Atom feeds
  // Handles: <item> (RSS) and <entry> (Atom)
  let currentItem: Partial<ParsedFeedItem> | null = null
  let currentTag = ''
  let isItem = false
  let isEntry = false
  let inContent = false

  // Parse line by line (simplified but functional for standard feeds)
  const lines = xmlContent.split('\n')
  for (const rawLine of lines) {
    const line = rawLine.trim()
    if (line.length === 0) continue

    // Detect item/entry start
    if (line.startsWith('<item') || line.startsWith('<entry')) {
      currentItem = {
        title: '',
        plainTitle: '',
        plainSnippet: '',
        link: '',
        guid: '',
        pubDate: Date.now(),
        author: '',
        imageUrl: '',
        enclosureLink: '',
        enclosureType: '',
        htmlContent: '',
      }
      isItem = true
      isEntry = line.startsWith('<entry')
      continue
    }

    // Detect item/entry end
    if ((isItem && line.startsWith('</item>')) || (isEntry && line.startsWith('</entry>'))) {
      if (currentItem !== null) {
        // Generate guid if missing
        if (!currentItem.guid || currentItem.guid.length === 0) {
          currentItem.guid = currentItem.link ?? `${Date.now()}-${Math.random()}`
        }
        items.push(currentItem as ParsedFeedItem)
      }
      currentItem = null
      isItem = false
      isEntry = false
      continue
    }

    if (!isItem || currentItem === null) continue

    // Parse tags within item
    const tagMatch = line.match(/^<(\w+)[\s>]/)
    if (tagMatch) {
      currentTag = tagMatch[1].toLowerCase()
      // Handle self-closing tags
      if (line.endsWith('/>')) {
        // Parse attributes from self-closing tags
        if (currentTag === 'enclosure' || currentTag === 'link') {
          parseAttributes(line, currentItem, currentTag)
        }
        currentTag = ''
        continue
      }
    }

    // Extract text content from the current tag
    const textContent = extractTextContent(line)
    if (textContent.length === 0) continue

    switch (currentTag) {
      case 'title':
        if (!currentItem.title || currentItem.title.length === 0) {
          currentItem.title = textContent
          currentItem.plainTitle = stripHtml(textContent)
        }
        break
      case 'link':
        if (isEntry) {
          // Atom: <link href="..."/> or <link>text</link>
          const href = extractAttribute(line, 'href')
          if (href && href.length > 0) {
            currentItem.link = href
          } else if (textContent.startsWith('http')) {
            currentItem.link = textContent
          }
        } else {
          // RSS: <link>text</link>
          if (textContent.startsWith('http')) {
            currentItem.link = textContent
          }
        }
        break
      case 'guid':
      case 'id':
        if (!currentItem.guid || currentItem.guid.length === 0) {
          currentItem.guid = textContent
        }
        break
      case 'pubdate':
      case 'published':
      case 'updated':
        currentItem.pubDate = parseDate(textContent)
        break
      case 'dc:date':
        currentItem.pubDate = parseDate(textContent)
        break
      case 'author':
      case 'name':
        if (!currentItem.author || currentItem.author.length === 0) {
          currentItem.author = textContent
        }
        break
      case 'description':
      case 'summary':
      case 'content':
        if (textContent.length > 0) {
          currentItem.htmlContent = textContent
          currentItem.plainSnippet = stripHtml(textContent).substring(0, 200)
        }
        break
      case 'media:content':
      case 'media:thumbnail':
        const imgUrl = extractAttribute(line, 'url')
        if (imgUrl && imgUrl.length > 0 && (!currentItem.imageUrl || currentItem.imageUrl.length === 0)) {
          currentItem.imageUrl = imgUrl
        }
        break
    }
  }
}

export function discoverFeeds(htmlContent: string): DiscoveryResult[] {
  const results: DiscoveryResult[] = []
  // Look for <link rel="alternate" type="application/rss+xml" ...> or
  // <link rel="alternate" type="application/atom+xml" ...>
  const linkRegex = /<link[^>]*rel\s*=\s*["']alternate["'][^>]*>/gi
  let match: RegExpExecArray | null
  while ((match = linkRegex.exec(htmlContent)) !== null) {
    const linkTag = match[0]
    const type = extractAttribute(linkTag, 'type') ?? ''
    if (type.includes('rss') || type.includes('atom')) {
      const href = extractAttribute(linkTag, 'href') ?? ''
      const title = extractAttribute(linkTag, 'title') ?? ''
      if (href.length > 0) {
        results.push({
          feedUrl: href,
          title: title.length > 0 ? title : href,
          description: '',
        })
      }
    }
  }
  // Also check for <feed> root element (direct RSS/Atom URL)
  if (htmlContent.includes('<rss') || htmlContent.includes('<feed')) {
    // The URL itself is a feed
    const titleMatch = htmlContent.match(/<title[^>]*>([\s\S]*?)<\/title>/i)
    const descMatch = htmlContent.match(/<description[^>]*>([\s\S]*?)<\/description>/i) ??
                      htmlContent.match(/<subtitle[^>]*>([\s\S]*?)<\/subtitle>/i)
    results.push({
      feedUrl: '',
      title: titleMatch ? stripHtml(titleMatch[1]) : 'Discovered Feed',
      description: descMatch ? stripHtml(descMatch[1]) : '',
    })
  }
  return results
}

// Helper: extract feed metadata from RSS/Atom XML
export function parseFeedMeta(xmlContent: string): ParsedFeedMeta {
  const titleMatch = xmlContent.match(/<title[^>]*>([\s\S]*?)<\/title>/i)
  const descMatch = xmlContent.match(/<description[^>]*>([\s\S]*?)<\/description>/i) ??
                    xmlContent.match(/<subtitle[^>]*>([\s\S]*?)<\/subtitle>/i)
  const linkMatch = xmlContent.match(/<link[^>]*href\s*=\s*["']([^"']*)["'][^>]*>/i) ??
                    xmlContent.match(/<link>([\s\S]*?)<\/link>/i)

  return {
    title: titleMatch ? stripHtml(titleMatch[1]) : '',
    description: descMatch ? stripHtml(descMatch[1]) : '',
    link: linkMatch ? (linkMatch[1] ?? '').trim() : '',
    feedUrl: '',
  }
}

// Helper functions

function extractTextContent(line: string): string {
  // Remove CDATA sections
  let text = line.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
  // Remove HTML tags
  text = text.replace(/<[^>]+>/g, '')
  // Decode common HTML entities
  text = text.replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
  return text.trim()
}

function extractAttribute(tag: string, attrName: string): string | null {
  const regex = new RegExp(`${attrName}\\s*=\\s*["']([^"']*)["']`, 'i')
  const match = tag.match(regex)
  return match ? match[1] : null
}

function parseAttributes(line: string, item: Partial<ParsedFeedItem>, tag: string): void {
  if (tag === 'enclosure') {
    const url = extractAttribute(line, 'url')
    const type = extractAttribute(line, 'type')
    if (url) {
      item.enclosureLink = url
      item.enclosureType = type ?? ''
    }
  } else if (tag === 'link') {
    const href = extractAttribute(line, 'href')
    if (href && href.startsWith('http')) {
      item.link = href
    }
  }
}

function stripHtml(html: string): string {
  return html.replace(/<[^>]+>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .trim()
}

function parseDate(dateStr: string): number {
  try {
    const d = new Date(dateStr)
    if (!isNaN(d.getTime())) {
      return d.getTime()
    }
  } catch (e) {
    // Fall through
  }
  return Date.now()
}
