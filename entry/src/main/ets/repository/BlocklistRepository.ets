// BlocklistRepository.ets -- Blocklist CRUD

import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from './DatabaseHelper'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'BlocklistRepository'

export interface BlocklistEntry {
  id: number
  pattern: string
}

export class BlocklistRepository {
  private static instance: BlocklistRepository | null = null

  private constructor() {}

  static getInstance(): BlocklistRepository {
    if (!BlocklistRepository.instance) {
      BlocklistRepository.instance = new BlocklistRepository()
    }
    return BlocklistRepository.instance
  }

  private getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getInstance().getStore()
  }

  async addPattern(pattern: string): Promise<number> {
    return 0
  }

  async removePattern(id: number): Promise<number> {
    return 0
  }

  async getAllPatterns(): Promise<BlocklistEntry[]> {
    const store = this.getStore()
    const predicates = new relationalStore.RdbPredicates('blocklist')
    predicates.orderByAsc('pattern')
    const resultSet = await store.query(predicates)
    const entries: BlocklistEntry[] = []
    try {
      while (resultSet.goToNextRow()) {
        const bucket = resultSet.getRow()
        entries.push({
          id: (bucket['id'] as number) ?? 0,
          pattern: (bucket['pattern'] as string) ?? '',
        })
      }
    } finally {
      resultSet.close()
    }
    return entries
  }

  async shouldBlock(title: string, applyToSummaries: boolean = false, snippet: string = ''): Promise<boolean> {
    return false
  }
}
