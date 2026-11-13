import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, SessionUsage } from 'claude-code'

import type { ApiUsage, Bucket, CacheState, Limit, Snapshot, Tokens, Totals } from '../types'
import {
  cacheFromTranscript,
  cacheSecondsLeft,
  elapsedPercent,
  FIVE_HOURS_MS,
  offPeak,
  pace,
  parseUsage,
  retryAfterSeconds,
  SEVEN_DAYS_MS,
  transcriptPath,
} from './limits'

const PANE = 'usage-monitor'
const DAY_MS = 24 * 60 * 60 * 1000
const KEEP_DAYS = 30
const ALERTS = [95, 80]
const TICK_MS = 60_000

const USAGE_URL = 'https://api.anthropic.com/api/oauth/usage'
// How long a usage API answer is reused, by every session, and how long one
// session's attempt holds the others off.
const USAGE_MAX_AGE_MS = 180_000
const USAGE_LOCK_MS = 30_000

const snapshot = atom({ plugin: 'usage-monitor', key: 'snapshot' } as const, null)
const totals = atom({ plugin: 'usage-monitor', key: 'totals' } as const, {
  today: emptyBucket(),
  week: emptyBucket(),
  month: emptyBucket(),
})
const isBandHidden = atom({ plugin: 'usage-monitor', key: 'isBandHidden' } as const, false)
const api = atom({ plugin: 'usage-monitor', key: 'api' } as const, null)
const cache = atom({ plugin: 'usage-monitor', key: 'cache' } as const, null)
// Bumped every minute so countdowns redraw.
const tick = atom({ plugin: 'usage-monitor', key: 'tick' } as const, 0)

// One store key per session, so sessions in other terminals never overwrite
// each other. `lastUsd` is the session cost already counted into `days`.
type SessionRecord = { days: Record<string, Bucket>; lastUsd: number; updatedAt: number }

// Which alert level each limit has already raised, per reset period. Shared
// by every session, so only one terminal toasts.
type Alerts = Record<string, { resetsAt?: string; level: number }>

// The last usage API answer, shared by every session so they poll it once.
type ApiRecord = { usage?: ApiUsage; lockedAt?: number; retryAt?: number }

type Elements = Pick<ReturnType<EngineInterface['ui']['resolve']>, 'Box' | 'Text'>

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'usage-monitor',
      description: 'Show subscription and API-priced usage in a pane (`band` toggles the band)',
      argumentHint: '[band]',
    })
    await prune($)
    await measure($, await $.session.usage())
    await restoreCache($)
    await pollUsage($)
    $.clock.every(TICK_MS, () => void minute($))

    return next(e)
  })

  // A resume, /clear or fork inside the process changes the session id with
  // no session.start: follow it to the session now running.
  on('classic.SessionStart', async ($, e, next) => {
    if (e.source === 'resume' || e.source === 'clear' || e.source === 'fork') {
      await measure($, await $.session.usage())
      await syncSession($)
      await restoreCache($)
    }

    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    await measure($, e)

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const usage = e.usage
    if (usage) {
      const tokens = toTokens(usage)
      await withRecord($, (record, now) => {
        const bucket = bucketFor(record, now)
        bucket.models = addModel(bucket.models, usage.model, tokens)

        return true
      })
      await syncSession($)
      await refreshTotals($)
      if (!e.agentId && tokens.cacheRead + tokens.cacheWrite > 0) await touchCache($)
    }

    return next(e)
  })

  on('command.run', { command: 'usage-monitor' }, async ($, e) => {
    if (e.args.trim() === 'band') {
      const hidden = await update($, isBandHidden, value => !value)

      return { text: hidden ? 'Usage band hidden.' : 'Usage band shown.' }
    }
    await $.ui.open({ id: PANE, title: 'Usage' })

    return { text: 'Usage pane opened.' }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const snap = await read($, snapshot)
    if (e.props.hasSurvey || snap === null || (await read($, isBandHidden))) {
      return next(e)
    }
    await read($, tick)
    const usage = await read($, api)
    const cached = await read($, cache)
    const { today } = await read($, totals)
    const now = await $.clock.now()
    const limits = limitsOf(snap, usage)
    const { Text } = $.ui.resolve(e)

    const parts: string[] = []
    for (const l of limits) {
      if (l.kind === 'session') {
        parts.push(`5h ${percent(l.percent)}${l.resetsAt ? ` ${duration(Date.parse(l.resetsAt) - now)}` : ''}`)
      } else if (l.kind === 'weekly') {
        const delta = pace(l, SEVEN_DAYS_MS, now)
        parts.push(`7d ${percent(l.percent)}${delta === undefined ? '' : ` pace ${signed(delta)}`}`)
      } else {
        parts.push(`${l.model!.toLowerCase()} ${percent(l.percent)}`)
      }
    }
    if (usage?.extra && usage.extra.usedCents > 0) {
      parts.push(`extra ${money(usage.extra.usedCents, usage.extra.currency)}`)
    }
    parts.push(`session ${usd(snap.costUsd)}`, `today ${usd(today.usd)}`)
    if (snap.context.percent !== undefined) parts.push(`ctx ${snap.context.percent}%`)
    if (cached) {
      const left = cacheSecondsLeft(cached, now)
      parts.push(left > 0 ? `cache ${Math.ceil(left / 60)}m` : 'cache cold')
    }

    return <Text dimColor>{parts.join(' · ')}</Text>
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    await read($, tick)
    const snap = await read($, snapshot)
    const usage = await read($, api)
    const cached = await read($, cache)
    const sums = await read($, totals)
    const now = await $.clock.now()
    const width = Math.max(10, Math.min(30, (e.viewport?.columns ?? 40) - 26))
    const limits = snap ? limitsOf(snap, usage) : []
    const peak = offPeak(now)

    return (
      <Box flexDirection="column" gap={1}>
        <Box flexDirection="column">
          <Text bold>Subscription</Text>
          {limits.length === 0 && <Text dimColor>No subscription limits reported.</Text>}
          {limits.map(l => (
            <Box flexDirection="column">
              <Text>
                {limitLabel(l).padEnd(10)} {bar(l.percent, width)} {percent(l.percent).padStart(4)}
                <Text dimColor>{l.resetsAt ? `  resets in ${duration(Date.parse(l.resetsAt) - now)}` : ''}</Text>
              </Text>
              {l.kind === 'session' && elapsedRow(Text, 'block', elapsedPercent(l.resetsAt, FIVE_HOURS_MS, now), width)}
              {l.kind === 'weekly' && paceRow(Text, pace(l, SEVEN_DAYS_MS, now), width)}
            </Box>
          ))}
          {usage?.extra && (
            <Text>
              {'Extra'.padEnd(10)} {bar(usage.extra.percent, width)} {percent(usage.extra.percent).padStart(4)}
              <Text dimColor>
                {'  '}
                {money(usage.extra.usedCents, usage.extra.currency)} of {money(usage.extra.limitCents, usage.extra.currency)}
              </Text>
            </Text>
          )}
          <Text dimColor>
            {peak.isPeak ? 'Peak hours' : 'Off-peak'}, {peak.isPeak ? 'off-peak' : 'peak'} in {duration(peak.flipsInMs)}
            {'  ·  '}
            {usage ? `usage API, ${duration(now - usage.fetchedAt)} ago` : 'from Claude Code (usage API unavailable)'}
          </Text>
        </Box>
        <Box flexDirection="column">
          <Text bold>This session</Text>
          <Text>
            Cost {usd(snap?.costUsd ?? 0)}
            {snap?.context.percent === undefined ? '' : `  ·  context ${snap.context.percent}% of ${count(snap.context.window)}`}
            {cached ? `  ·  ${cacheText(cached, now)}` : ''}
          </Text>
          {modelRows({ Box, Text }, snap?.models ?? {})}
        </Box>
        <Box flexDirection="column">
          <Text bold>API-priced cost</Text>
          {(
            [
              ['Today', sums.today],
              ['7 days', sums.week],
              ['30 days', sums.month],
            ] as const
          ).map(([label, bucket]) => (
            <Text>
              {label.padEnd(8)} {usd(bucket.usd).padStart(9)}
              <Text dimColor>  {count(totalTokens(bucket.models))} tokens</Text>
            </Text>
          ))}
          {modelRows({ Box, Text }, sums.month.models)}
        </Box>
      </Box>
    )
  })
}

// The limits to show: the usage API's when it answered (it has the per-model
// ones), else the two windows Claude Code reports.
function limitsOf(snap: Snapshot, usage: ApiUsage | null): Limit[] {
  if (usage) return usage.limits

  return snap.rateLimits.flatMap((w): Limit[] => {
    const base = { percent: w.percentUsed, resetsAt: w.resetsAt }
    if (w.kind === 'five_hour') return [{ kind: 'session', ...base }]
    if (w.kind === 'seven_day') return [{ kind: 'weekly', ...base }]

    return []
  })
}

function elapsedRow(Text: Elements['Text'], label: string, elapsed: number | undefined, width: number) {
  if (elapsed === undefined) return null

  return (
    <Text dimColor>
      {`  ${label}`.padEnd(10)} {bar(elapsed, width)} {percent(elapsed).padStart(4)}  elapsed
    </Text>
  )
}

// A pendulum around even pace: right of center is ahead of it, left behind.
function paceRow(Text: Elements['Text'], delta: number | undefined, width: number) {
  if (delta === undefined) return null
  const half = Math.floor(width / 2)
  const fill = Math.min(half, Math.round((Math.abs(delta) / 100) * half))
  const left = delta < 0 ? '─'.repeat(half - fill) + '█'.repeat(fill) : '─'.repeat(half)
  const right = delta > 0 ? '█'.repeat(fill) + '─'.repeat(half - fill) : '─'.repeat(half)
  const words = Math.abs(delta) < 1 ? 'on pace' : delta > 0 ? 'ahead of pace' : 'under pace'

  return (
    <Text dimColor>
      {'  pace'.padEnd(10)} {left}│{right} {signed(delta).padStart(4)}  {words}
    </Text>
  )
}

function modelRows({ Box, Text }: Elements, models: Record<string, Tokens>) {
  const names = Object.keys(models).sort((a, b) => sum(models[b]!) - sum(models[a]!))
  if (names.length === 0) return <Text dimColor>No turns yet.</Text>

  return (
    <Box flexDirection="column">
      <Text dimColor>
        {'model'.padEnd(20)} {'in'.padStart(7)} {'out'.padStart(7)} {'c.read'.padStart(7)} {'c.write'.padStart(7)}
      </Text>
      {names.map(name => {
        const t = models[name]!

        return (
          <Text>
            {shortModel(name).padEnd(20)} {count(t.input).padStart(7)} {count(t.output).padStart(7)}{' '}
            {count(t.cacheRead).padStart(7)} {count(t.cacheWrite).padStart(7)}
          </Text>
        )
      })}
    </Box>
  )
}

async function minute($: EngineInterface) {
  await update($, tick, n => n + 1)
  await pollUsage($)
}

// Fetches the subscription limits from the usage API with the session's own
// login (the token never reaches this module), at most once per
// USAGE_MAX_AGE_MS across every session.
async function pollUsage($: EngineInterface) {
  const now = await $.clock.now()
  const record = ((await $.store.get('api')) as ApiRecord | undefined) ?? {}
  const isFresh = record.usage !== undefined && now - record.usage.fetchedAt < USAGE_MAX_AGE_MS
  const isHeld = (record.retryAt ?? 0) > now || now - (record.lockedAt ?? 0) < USAGE_LOCK_MS

  if (!isFresh && !isHeld) {
    await $.store.set('api', { ...record, lockedAt: now })
    const auth = await $.session.authorize()
    if (auth?.kind === 'bearer') {
      const res = await $.http
        .fetch(USAGE_URL, { headers: { 'anthropic-beta': 'oauth-2025-04-20' }, auth: auth.handle })
        .catch(() => undefined)
      if (res?.status === 429) {
        record.retryAt = now + retryAfterSeconds(res.headers) * 1000
      } else if (res?.ok) {
        const usage = parseUsage(safeJson(res.text), now)
        if (usage) record.usage = usage
      }
      await $.store.set('api', { ...record, lockedAt: undefined })
    }
  }

  // An answer older than a window's reset would show stale numbers: past
  // 15 minutes, fall back to what Claude Code reports.
  const usage = record.usage && now - record.usage.fetchedAt < 15 * 60_000 ? record.usage : null
  await update($, api, () => usage)
  if (usage) await alert($, usage.limits)
}

async function touchCache($: EngineInterface) {
  const now = await $.clock.now()
  const ttl = (await readTranscriptCache($))?.ttlSeconds ?? (await read($, cache))?.ttlSeconds ?? 300
  await update($, cache, (): CacheState => ({ at: now, ttlSeconds: ttl }))
}

// After a resume: the cache as the resumed transcript last left it.
async function restoreCache($: EngineInterface) {
  const found = await readTranscriptCache($)
  const at = found?.at
  await update($, cache, () => (at === undefined ? null : { at, ttlSeconds: found?.ttlSeconds ?? 300 }))
}

async function readTranscriptCache($: EngineInterface) {
  const home = await $.env.get('HOME')
  const configDir = (await $.env.get('CLAUDE_CONFIG_DIR')) ?? (home ? `${home}/.claude` : undefined)
  if (!configDir) return undefined
  const path = transcriptPath(configDir, await $.session.cwd(), await $.session.id())
  const tail = await $.process.run(['tail', '-c', '262144', path], { timeoutMs: 5000 }).catch(() => undefined)

  return tail?.exitCode === 0 ? cacheFromTranscript(tail.stdout) : undefined
}

// Serializes read-modify-write of this session's store key.
let queue = Promise.resolve()

// `fn` answers whether it changed the record; an unchanged one is not saved,
// so a process that starts and resumes another session leaves no record.
async function withRecord($: EngineInterface, fn: (r: SessionRecord, now: number) => boolean) {
  queue = queue.then(async () => {
    const key = `s:${await $.session.id()}`
    const record = ((await $.store.get(key)) as SessionRecord | undefined) ?? {
      days: {},
      lastUsd: 0,
      updatedAt: 0,
    }
    const now = await $.clock.now()
    if (!fn(record, now)) return
    record.updatedAt = now
    await $.store.set(key, record)
  })

  return queue
}

async function measure($: EngineInterface, usage: Omit<SessionUsage, 'startedAt'>) {
  await update($, snapshot, prev => ({
    rateLimits: usage.rateLimits.map(w => ({ ...w })),
    costUsd: prev?.costUsd ?? 0,
    context: {
      tokens: usage.context.tokens,
      window: usage.context.window,
      percent: usage.context.percent,
    },
    models: prev?.models ?? {},
  }))

  if (usage.cost) {
    const usd = usage.cost.usd
    await withRecord($, (record, now) => {
      // The ledger restarts on /clear: count the new total from zero.
      // So does Claude Code's own counter when a session is resumed in a new
      // process: either way the record keeps what was already counted.
      const delta = usd >= record.lastUsd ? usd - record.lastUsd : usd
      if (delta <= 0 && usd === record.lastUsd) return false
      record.lastUsd = usd
      if (delta > 0) bucketFor(record, now).usd += delta

      return true
    })
  }
  await syncSession($)

  await refreshTotals($)
  const snap = await read($, snapshot)
  if (snap && !(await read($, api))) await alert($, limitsOf(snap, null))
}

// The session's cost and tokens, from its record: every process that ran
// it, so a resumed session keeps counting from where it was.
async function syncSession($: EngineInterface) {
  await queue
  const record = (await $.store.get(`s:${await $.session.id()}`)) as SessionRecord | undefined
  const whole = emptyBucket()
  for (const bucket of Object.values(record?.days ?? {})) addBucket(whole, bucket)
  await update($, snapshot, prev => (prev ? { ...prev, costUsd: whole.usd, models: whole.models } : prev))
}

async function refreshTotals($: EngineInterface) {
  const now = await $.clock.now()
  const today = dayKey(now)
  const week = dayKey(now - 6 * DAY_MS)
  const month = dayKey(now - (KEEP_DAYS - 1) * DAY_MS)
  const sums: Totals = { today: emptyBucket(), week: emptyBucket(), month: emptyBucket() }

  for (const key of await $.store.keys()) {
    if (!key.startsWith('s:')) continue
    const record = (await $.store.get(key)) as SessionRecord | undefined
    for (const [day, bucket] of Object.entries(record?.days ?? {})) {
      if (day >= month) addBucket(sums.month, bucket)
      if (day >= week) addBucket(sums.week, bucket)
      if (day === today) addBucket(sums.today, bucket)
    }
  }
  await update($, totals, () => sums)
}

async function prune($: EngineInterface) {
  const cutoff = (await $.clock.now()) - (KEEP_DAYS + 1) * DAY_MS
  for (const key of await $.store.keys()) {
    if (!key.startsWith('s:')) continue
    const record = (await $.store.get(key)) as SessionRecord | undefined
    const isEmpty = Object.keys(record?.days ?? {}).length === 0
    if (!record || record.updatedAt < cutoff || isEmpty) await $.store.delete(key)
  }
}

async function alert($: EngineInterface, limits: Limit[]) {
  const seen = ((await $.store.get('alerts')) as Alerts | undefined) ?? {}
  const now = await $.clock.now()
  const raised: string[] = []
  let isChanged = false

  for (const l of limits) {
    const key = l.model ? `model:${l.model}` : l.kind
    const level = ALERTS.find(a => l.percent >= a) ?? 0
    const prev = seen[key]
    if (prev && prev.resetsAt === l.resetsAt && level <= prev.level) continue
    if (level > 0) {
      const resets = l.resetsAt ? `, resets in ${duration(Date.parse(l.resetsAt) - now)}` : ''
      raised.push(`${limitLabel(l)} usage at ${percent(l.percent)}${resets}`)
    }
    seen[key] = { resetsAt: l.resetsAt, level }
    isChanged = true
  }
  if (!isChanged) return
  // Recorded before toasting, so a toast that fails never raises twice.
  await $.store.set('alerts', seen)
  for (const text of raised) $.ui.toast(text)
}

function bucketFor(record: SessionRecord, now: number): Bucket {
  const day = dayKey(now)
  record.days[day] ??= emptyBucket()

  return record.days[day]
}

function emptyBucket(): Bucket {
  return { usd: 0, models: {} }
}

function addBucket(into: Bucket, from: Bucket) {
  into.usd += from.usd
  for (const [model, tokens] of Object.entries(from.models)) {
    into.models = addModel(into.models, model, tokens)
  }
}

function addModel(models: Record<string, Tokens>, model: string, t: Tokens) {
  const prev = models[model] ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }

  return {
    ...models,
    [model]: {
      input: prev.input + t.input,
      output: prev.output + t.output,
      cacheRead: prev.cacheRead + t.cacheRead,
      cacheWrite: prev.cacheWrite + t.cacheWrite,
    },
  }
}

function toTokens(u: {
  input_tokens: number
  output_tokens: number
  cache_read_input_tokens: number
  cache_creation_input_tokens: number
}): Tokens {
  return {
    input: u.input_tokens,
    output: u.output_tokens,
    cacheRead: u.cache_read_input_tokens,
    cacheWrite: u.cache_creation_input_tokens,
  }
}

function sum(t: Tokens) {
  return t.input + t.output + t.cacheRead + t.cacheWrite
}

function totalTokens(models: Record<string, Tokens>) {
  return Object.values(models).reduce((n, t) => n + sum(t), 0)
}

function safeJson(text: string): unknown {
  try {
    return JSON.parse(text)
  } catch {
    return undefined
  }
}

function dayKey(ms: number) {
  const d = new Date(ms)
  const pad = (n: number) => String(n).padStart(2, '0')

  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

function limitLabel(l: Limit) {
  return l.kind === 'session' ? '5h' : l.kind === 'weekly' ? '7d' : `${l.model} 7d`
}

function cacheText(c: CacheState, now: number) {
  const left = cacheSecondsLeft(c, now)
  const ttl = c.ttlSeconds >= 3600 ? '1h' : '5m'

  return left > 0 ? `cache warm, ${Math.ceil(left / 60)}m left (${ttl} TTL)` : `cache cold (${ttl} TTL)`
}

function shortModel(id: string) {
  return id.replace(/^claude-/, '').replace(/-\d{8}$/, '')
}

function percent(n: number) {
  return `${Math.round(n)}%`
}

function signed(n: number) {
  const r = Math.round(n)

  return `${r > 0 ? '+' : ''}${r}%`
}

function usd(n: number) {
  return `$${n.toFixed(2)}`
}

function money(cents: number, currency: string) {
  const amount = (cents / 100).toFixed(2)

  return currency === 'USD' ? `$${amount}` : `${amount} ${currency}`
}

function count(n: number) {
  if (n >= 1e6) return `${(n / 1e6).toFixed(1)}M`
  if (n >= 1e3) return `${(n / 1e3).toFixed(1)}k`

  return String(n)
}

function bar(pct: number, width: number) {
  const filled = Math.min(width, Math.max(0, Math.round((pct / 100) * width)))

  return '█'.repeat(filled) + '░'.repeat(width - filled)
}

function duration(ms: number) {
  const minutes = Math.max(0, Math.round(ms / 60000))
  const days = Math.floor(minutes / 1440)
  const hours = Math.floor((minutes % 1440) / 60)

  return days > 0 ? `${days}d ${hours}h` : hours > 0 ? `${hours}h ${minutes % 60}m` : `${minutes}m`
}
