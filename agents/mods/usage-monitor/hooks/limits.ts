// Pure helpers for the usage API and the timers derived from it, after
// ccstatusline-usage (github.com/pcvelz/ccstatusline-usage).

import type { ApiUsage, ExtraUsage, Limit } from '../types'

export const FIVE_HOURS_MS = 5 * 60 * 60 * 1000
export const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000

// Peak hours are weekdays 12:00-18:00 UTC (8 AM-2 PM EDT).
const PEAK_START_UTC = 12
const PEAK_END_UTC = 18

// Seconds shaved off the cache TTL, so "warm" never means "just expired".
const CACHE_SAFETY_SECONDS = 5

type Json = Record<string, unknown>

const isObject = (v: unknown): v is Json => typeof v === 'object' && v !== null
const num = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? v : undefined)
const str = (v: unknown) => (typeof v === 'string' && v !== '' ? v : undefined)

// Reads `GET /api/oauth/usage`. The `limits` array is preferred: the older
// per-model `seven_day_opus` / `seven_day_sonnet` buckets often come back null.
// Utilization is a percentage (0-100); extra usage is in cents.
export function parseUsage(body: unknown, fetchedAt: number): ApiUsage | null {
  if (!isObject(body)) return null
  const entries = Array.isArray(body.limits) ? body.limits.filter(isObject) : []
  const limits: Limit[] = []

  const fromEntry = (kind: string) => entries.find(e => e.kind === kind)
  const fromBucket = (key: string) => {
    const b = body[key]

    return isObject(b) && num(b.utilization) !== undefined
      ? { percent: num(b.utilization)!, resetsAt: str(b.resets_at) }
      : undefined
  }
  const pick = (kind: string, bucket: string) => {
    const e = fromEntry(kind)
    if (e && num(e.percent) !== undefined && !(e.percent === 0 && !e.resets_at)) {
      return { percent: num(e.percent)!, resetsAt: str(e.resets_at) }
    }

    return fromBucket(bucket)
  }

  const session = pick('session', 'five_hour')
  const weekly = pick('weekly_all', 'seven_day')
  if (!session && !weekly) return null
  if (session) limits.push({ kind: 'session', ...session })
  if (weekly) limits.push({ kind: 'weekly', ...weekly })

  for (const e of entries) {
    if (e.kind !== 'weekly_scoped') continue
    const scope = isObject(e.scope) && isObject(e.scope.model) ? e.scope.model : undefined
    const model = str(scope?.display_name)
    const percent = num(e.percent)
    if (model && percent !== undefined) limits.push({ kind: 'model', model, percent, resetsAt: str(e.resets_at) })
  }
  for (const [key, model] of [
    ['seven_day_opus', 'Opus'],
    ['seven_day_sonnet', 'Sonnet'],
  ] as const) {
    const b = fromBucket(key)
    const isListed = limits.some(l => l.model?.toLowerCase().includes(model.toLowerCase()))
    if (b && !isListed) limits.push({ kind: 'model', model, ...b })
  }

  return { fetchedAt, limits, extra: parseExtra(body.extra_usage) }
}

function parseExtra(v: unknown): ExtraUsage | undefined {
  if (!isObject(v) || v.is_enabled !== true) return undefined

  return {
    usedCents: num(v.used_credits) ?? 0,
    limitCents: num(v.monthly_limit) ?? 0,
    percent: num(v.utilization) ?? 0,
    currency: str(v.currency) ?? 'USD',
  }
}

// Seconds to wait after a 429, from its `retry-after` header (300 without one).
export function retryAfterSeconds(headers: Record<string, string>) {
  const raw = headers['retry-after'] ?? headers['Retry-After']
  const seconds = raw === undefined ? NaN : Number(raw)

  return Number.isFinite(seconds) && seconds > 0 ? seconds : 300
}

// How far into a window `now` is, as a percentage of its length.
export function elapsedPercent(resetsAt: string | undefined, lengthMs: number, now: number) {
  if (!resetsAt) return undefined
  const left = Date.parse(resetsAt) - now
  if (!Number.isFinite(left)) return undefined

  return Math.min(100, Math.max(0, ((lengthMs - left) / lengthMs) * 100))
}

// Usage ahead of (positive) or behind (negative) an even burn over the window.
export function pace(limit: Limit | undefined, lengthMs: number, now: number) {
  const elapsed = elapsedPercent(limit?.resetsAt, lengthMs, now)

  return limit && elapsed !== undefined ? limit.percent - elapsed : undefined
}

export function offPeak(now: number) {
  const d = new Date(now)
  const day = d.getUTCDay()
  const isWeekday = day >= 1 && day <= 5
  const hour = d.getUTCHours()
  const isPeak = isWeekday && hour >= PEAK_START_UTC && hour < PEAK_END_UTC

  // The next flip: the end of today's peak, or the start of the next weekday's.
  const at = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()))
  if (isPeak) {
    at.setUTCHours(PEAK_END_UTC)
  } else {
    if (isWeekday && hour < PEAK_START_UTC) {
      at.setUTCHours(PEAK_START_UTC)
    } else {
      do at.setUTCDate(at.getUTCDate() + 1)
      while (at.getUTCDay() === 0 || at.getUTCDay() === 6)
      at.setUTCHours(PEAK_START_UTC)
    }
  }

  return { isPeak, flipsInMs: at.getTime() - now }
}

// The prompt cache as a transcript's tail last left it: when it was last read
// or written (`at`, from the row's timestamp) and its TTL from the newest
// write (3600 for the 1-hour cache, 300 for the 5-minute one). Either is
// undefined when the tail does not say.
export function cacheFromTranscript(tail: string) {
  let at: number | undefined
  let ttlSeconds: number | undefined
  const lines = tail.split('\n')
  for (let i = lines.length - 1; i >= 0 && (at === undefined || ttlSeconds === undefined); i--) {
    const line = lines[i]!
    if (!line.includes('"cache_')) continue
    let row: Json
    try {
      row = JSON.parse(line) as Json
    } catch {
      // The first line of a tail is usually cut mid-row.
      continue
    }
    const usage = isObject(row.message) && isObject(row.message.usage) ? row.message.usage : undefined
    if (!usage) continue
    const isActive = (num(usage.cache_read_input_tokens) ?? 0) + (num(usage.cache_creation_input_tokens) ?? 0) > 0
    const time = Date.parse(str(row.timestamp) ?? '')
    if (at === undefined && isActive && Number.isFinite(time)) at = time
    const creation = isObject(usage.cache_creation) ? usage.cache_creation : undefined
    if (ttlSeconds === undefined && (num(creation?.ephemeral_1h_input_tokens) ?? 0) > 0) ttlSeconds = 3600
    if (ttlSeconds === undefined && (num(creation?.ephemeral_5m_input_tokens) ?? 0) > 0) ttlSeconds = 300
  }

  return { at, ttlSeconds }
}

export function cacheSecondsLeft(cache: { at: number; ttlSeconds: number }, now: number) {
  return cache.ttlSeconds - CACHE_SAFETY_SECONDS - (now - cache.at) / 1000
}

// Where Claude Code keeps a session's transcript.
export function transcriptPath(configDir: string, cwd: string, sessionId: string) {
  return `${configDir}/projects/${cwd.replace(/[^a-zA-Z0-9]/g, '-')}/${sessionId}.jsonl`
}
