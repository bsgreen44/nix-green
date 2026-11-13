import { expect, mock, test } from 'claude-code/testing'
import type { On, SessionRateLimit } from 'claude-code'

const DAY = 24 * 60 * 60 * 1000
// Local noon, so day arithmetic never crosses midnight.
const NOON = new Date(2026, 10, 13, 12).getTime()

const BAND = {
  plugin: 'usage-monitor',
  component: 'AbovePrompt',
  props: { hasSurvey: false, isWorking: false, maxRows: 10, scroll: { offset: 0, bodyRows: 10 } },
} as const

const PANE = {
  plugin: 'usage-monitor',
  component: 'Pane',
  requestId: 'usage-monitor',
  props: {
    title: 'Usage',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 40 },
    view: {},
  },
} as const

const windows = (fiveHour: number): SessionRateLimit[] => [
  { kind: 'five_hour', percentUsed: fiveHour, resetsAt: new Date(NOON + 2 * 3600_000).toISOString() },
  { kind: 'seven_day', percentUsed: 18, resetsAt: new Date(NOON + 3 * DAY).toISOString() },
]

function engine(on: On, store: Record<string, unknown> = {}, usageApi?: unknown) {
  const clock = mock.clock(on, { now: NOON })
  // The store in memory, kept here rather than in mock.store so a test can
  // read what the plugin left in it.
  const kept = new Map(Object.entries(store))
  on('store.get', (_, e) => ({ value: kept.get(e.key) }))
  on('store.set', (_, e) => (kept.set(e.key, JSON.parse(JSON.stringify(e.value))), { value: undefined }))
  on('store.delete', (_, e) => (kept.delete(e.key), { value: undefined }))
  on('store.keys', () => ({ value: [...kept.keys()] }))
  const toasts: string[] = []
  const fetches: string[] = []
  // The running session's id, and each session's transcript tail.
  const session = { id: 'one' }
  const transcripts = new Map([['one', JSON.stringify(cacheRow())]])
  on('session.id', () => ({ value: session.id }))
  on('session.usage', () => ({
    value: { startedAt: NOON, context: { window: 200_000 }, rateLimits: [], cost: { usd: 0 } },
  }))
  on('command.register', () => ({ value: { command: 'usage-monitor' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.toast', (_, e) => (toasts.push(e.text), { value: undefined }))
  on('session.authorize', () => ({ value: usageApi ? { handle: 'h', kind: 'bearer' as const } : null }))
  on('http.fetch', (_, e) => {
    fetches.push(e.url)

    return { value: { status: 200, ok: true, headers: {}, text: JSON.stringify(usageApi) } }
  })
  on('env.get', (_, e) => ({ value: e.name === 'HOME' ? '/home/me' : undefined }))
  on('session.cwd', () => ({ value: '/work' }))
  on('process.run', (_, e) => {
    const id = e.argv.join(' ').match(/^tail -c 262144 \/home\/me\/\.claude\/projects\/-work\/(.+)\.jsonl$/)?.[1]
    const tail = id === undefined ? undefined : transcripts.get(id)

    return { value: { exitCode: tail === undefined ? 1 : 0, stdout: tail ?? '', stderr: '' } }
  })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.measure', (_, e) => ({ changed: e.changed }))
  on('turn.complete', (_, e) => ({ text: e.answer }))
  on('classic.SessionStart', () => ({}))

  return { clock, toasts, kept, fetches, session, transcripts }
}

// A transcript row that wrote the 1-hour cache, at `timestamp` when given.
function cacheRow(timestamp?: string) {
  return {
    timestamp,
    message: {
      usage: {
        cache_read_input_tokens: 0,
        cache_creation_input_tokens: 700,
        cache_creation: { ephemeral_1h_input_tokens: 700, ephemeral_5m_input_tokens: 0 },
      },
    },
  }
}

const measured = (usd: number, fiveHour = 42) => ({
  context: { tokens: 74_000, window: 200_000, percent: 37 },
  rateLimits: windows(fiveHour),
  cost: { usd },
  changed: ['cost' as const],
})

test('the band shows windows, session and today cost on every surface', async ($, on) => {
  engine(on, {
    // Another terminal's session today, and one from ten days ago.
    's:two': { days: { [dayKey(NOON)]: { usd: 2, models: {} } }, lastUsd: 2, updatedAt: NOON },
    's:old': { days: { [dayKey(NOON - 10 * DAY)]: { usd: 5, models: {} } }, lastUsd: 5, updatedAt: NOON - 10 * DAY },
  })
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.session.measure(measured(1.5))

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ ...BAND, surface })
    const band = await ui.find({ type: 'Text', text: /session/ })
    expect(band?.text).toBe('5h 42% 2h 0m · 7d 18% pace -39% · session $1.50 · today $3.50 · ctx 37%')
    await ui.unmount()
  }
})

test('cost that goes down after /clear counts from zero', async ($, on) => {
  engine(on)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.session.measure(measured(4))
  await $.session.measure(measured(1))

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /^Today/ }))?.text).toMatch(/\$5\.00/)
  await ui.unmount()
})

test('the pane sums 7 and 30 days and lists tokens by model', async ($, on) => {
  const { clock } = engine(on, {
    's:a': { days: { [dayKey(NOON - 3 * DAY)]: { usd: 1, models: {} } }, lastUsd: 1, updatedAt: NOON - 3 * DAY },
    's:b': { days: { [dayKey(NOON - 20 * DAY)]: { usd: 10, models: {} } }, lastUsd: 10, updatedAt: NOON - 20 * DAY },
  })
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.turn.complete({
    answer: 'ok',
    durationMs: 1,
    isAborted: false,
    turnId: 't1',
    reason: 'answer',
    usage: {
      model: 'claude-opus-5-5',
      input_tokens: 1200,
      output_tokens: 300,
      cache_read_input_tokens: 2_500_000,
      cache_creation_input_tokens: 0,
    },
  })
  await $.session.measure(measured(0.25))

  const ui = await $.ui.mount({ ...PANE, surface: 'desktop' })
  expect((await ui.find({ type: 'Text', text: /^Today/ }))?.text).toMatch(/\$0\.25/)
  expect((await ui.find({ type: 'Text', text: /^7 days/ }))?.text).toMatch(/\$1\.25/)
  expect((await ui.find({ type: 'Text', text: /^30 days/ }))?.text).toMatch(/\$11\.25/)
  expect((await ui.find({ type: 'Text', text: /^opus-5-5/ }))?.text).toMatch(/1\.2k\s+300\s+2\.5M\s+0/)
  expect((await ui.find({ type: 'Text', text: /^Cost/ }))?.text).toMatch(/cache warm, 60m left \(1h TTL\)/)
  await ui.unmount()

  await clock.advance(61 * 60_000)
  const band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect((await band.find({ type: 'Text', text: /session/ }))?.text).toMatch(/cache cold$/)
  await band.unmount()
})

test('sessions idle for over 30 days are pruned', async ($, on) => {
  const { kept } = engine(on, {
    's:stale': { days: { [dayKey(NOON - 40 * DAY)]: { usd: 9, models: {} } }, lastUsd: 9, updatedAt: NOON - 40 * DAY },
  })
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  expect(kept.has('s:stale')).toBe(false)
})

test('a window toasts once per level and reset period', async ($, on) => {
  const { toasts } = engine(on)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.session.measure(measured(0, 50))
  await $.session.measure(measured(0, 81))
  await $.session.measure(measured(0, 83))
  await $.session.measure(measured(0, 96))
  expect(toasts).toEqual(['5h usage at 81%, resets in 2h 0m', '5h usage at 96%, resets in 2h 0m'])
})

test('per-model limits, pace and extra usage come from the usage API', async ($, on) => {
  const { fetches, clock } = engine(on, {}, {
    five_hour: { utilization: 42, resets_at: new Date(NOON + 2 * 3600_000).toISOString() },
    seven_day: { utilization: 50, resets_at: new Date(NOON + 3.5 * DAY).toISOString() },
    seven_day_opus: null,
    limits: [
      {
        kind: 'weekly_scoped',
        percent: 30,
        resets_at: new Date(NOON + 3.5 * DAY).toISOString(),
        scope: { model: { display_name: 'Opus' } },
      },
    ],
    extra_usage: { is_enabled: true, monthly_limit: 5000, used_credits: 320, utilization: 6.4, currency: 'USD' },
  })
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.session.measure(measured(1.5))

  const band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect((await band.find({ type: 'Text', text: /session/ }))?.text).toBe(
    '5h 42% 2h 0m · 7d 50% pace 0% · opus 30% · extra $3.20 · session $1.50 · today $1.50 · ctx 37%',
  )
  await band.unmount()

  const pane = await $.ui.mount({ ...PANE, surface: 'desktop' })
  expect((await pane.find({ type: 'Text', text: /^Opus 7d/ }))?.text).toMatch(/30%\s+resets in 3d 12h/)
  expect((await pane.find({ type: 'Text', text: /^Extra/ }))?.text).toMatch(/\$3\.20 of \$50\.00/)
  expect((await pane.find({ type: 'Text', text: /pace/ }))?.text).toMatch(/on pace/)
  expect((await pane.find({ type: 'Text', text: /block/ }))?.text).toMatch(/60%\s+elapsed/)
  await pane.unmount()

  // Polled once, then reused for three minutes.
  await clock.advance(60_000)
  expect(fetches).toEqual(['https://api.anthropic.com/api/oauth/usage'])
  await clock.advance(3 * 60_000)
  expect(fetches.length).toBe(2)
})

test('a session resumed in a new process keeps its cost, tokens and cache', async ($, on) => {
  const { session, transcripts, kept } = engine(on, {
    's:old': {
      days: {
        [dayKey(NOON)]: {
          usd: 4,
          models: { 'claude-opus-5-5': { input: 1000, output: 200, cacheRead: 0, cacheWrite: 0 } },
        },
      },
      lastUsd: 4,
      updatedAt: NOON - 60_000,
    },
  })
  transcripts.set('old', JSON.stringify(cacheRow(new Date(NOON - 10 * 60_000).toISOString())))

  // The process starts under a fresh id, then the person resumes `old`.
  session.id = 'fresh'
  await $.session.start({ cwd: '/work', surface: 'terminal', isInteractive: true })
  session.id = 'old'
  await $.classic.SessionStart({ source: 'resume' })
  // Claude Code's cost counter starts over in the new process.
  await $.session.measure(measured(0.5))

  const band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect((await band.find({ type: 'Text', text: /session/ }))?.text).toMatch(/session \$4\.50 · today \$4\.50 · ctx 37% · cache 50m$/)
  await band.unmount()
  const pane = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await pane.find({ type: 'Text', text: /^opus-5-5/ }))?.text).toMatch(/1\.0k\s+200/)
  await pane.unmount()
  expect([...kept.keys()].filter(k => k.startsWith('s:'))).toEqual(['s:old'])
})

function dayKey(ms: number) {
  const d = new Date(ms)
  const pad = (n: number) => String(n).padStart(2, '0')

  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}
