export type Tokens = {
  input: number
  output: number
  cacheRead: number
  cacheWrite: number
}

export type Window = { kind: string; percentUsed: number; resetsAt?: string }

export type Snapshot = {
  rateLimits: Window[]
  costUsd: number
  context: { tokens?: number; window: number; percent?: number }
  models: Record<string, Tokens>
}

export type Bucket = { usd: number; models: Record<string, Tokens> }

export type Totals = { today: Bucket; week: Bucket; month: Bucket }

// One limit the usage API reports: the 5-hour session, the whole week, or the
// week for one model (`model` set).
export type Limit = {
  kind: 'session' | 'weekly' | 'model'
  model?: string
  percent: number
  resetsAt?: string
}

export type ExtraUsage = {
  usedCents: number
  limitCents: number
  percent: number
  currency: string
}

export type ApiUsage = { fetchedAt: number; limits: Limit[]; extra?: ExtraUsage }

// When the prompt cache was last written or read on the main thread, and for
// how long it lives.
export type CacheState = { at: number; ttlSeconds: number }

declare module 'claude-code' {
  interface PluginState {
    'usage-monitor': {
      snapshot: Snapshot | null
      totals: Totals
      isBandHidden: boolean
      api: ApiUsage | null
      cache: CacheState | null
      tick: number
    }
  }
}
