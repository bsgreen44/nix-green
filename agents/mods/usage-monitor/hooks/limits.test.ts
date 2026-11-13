import { expect, test } from 'claude-code/testing'

import { cacheFromTranscript, offPeak, pace, parseUsage, transcriptPath } from './limits'

test('limits[] wins over the legacy buckets, and a placeholder entry is skipped', () => {
  const usage = parseUsage(
    {
      five_hour: { utilization: 10, resets_at: '2026-11-13T20:00:00Z' },
      seven_day: { utilization: 20, resets_at: '2026-11-16T00:00:00Z' },
      seven_day_sonnet: { utilization: 5, resets_at: '2026-11-16T00:00:00Z' },
      limits: [
        { kind: 'session', percent: 0, resets_at: null },
        { kind: 'weekly_all', percent: 22, resets_at: '2026-11-16T00:00:00Z' },
        { kind: 'weekly_scoped', percent: 40, resets_at: '2026-11-16T00:00:00Z', scope: { model: { display_name: 'Fable' } } },
      ],
    },
    1,
  )
  expect(usage?.limits.map(l => [l.kind, l.model, l.percent])).toEqual([
    ['session', undefined, 10],
    ['weekly', undefined, 22],
    ['model', 'Fable', 40],
    ['model', 'Sonnet', 5],
  ])
  expect(usage?.extra).toBeUndefined()
})

test('a body with neither window is no answer', () => {
  expect(parseUsage({ error: 'nope' }, 1)).toBeNull()
  expect(parseUsage('text', 1)).toBeNull()
})

test('pace is usage minus the share of the window gone by', () => {
  const now = Date.parse('2026-11-13T00:00:00Z')
  const resetsAt = new Date(now + 3.5 * 24 * 3600_000).toISOString()
  expect(pace({ kind: 'weekly', percent: 70, resetsAt }, 7 * 24 * 3600_000, now)).toBe(20)
})

test('peak is weekdays 12-18 UTC', () => {
  expect(offPeak(Date.parse('2026-11-13T13:00:00Z'))).toEqual({ isPeak: true, flipsInMs: 5 * 3600_000 })
  expect(offPeak(Date.parse('2026-11-13T19:00:00Z'))).toEqual({ isPeak: false, flipsInMs: 65 * 3600_000 })
  expect(offPeak(Date.parse('2026-11-16T09:00:00Z'))).toEqual({ isPeak: false, flipsInMs: 3 * 3600_000 })
})

test('the cache is read from the newest cache rows in the transcript', () => {
  const row = (time: string, read: number, h1: number, m5: number) =>
    JSON.stringify({
      timestamp: time,
      message: {
        usage: {
          cache_read_input_tokens: read,
          cache_creation_input_tokens: h1 + m5,
          cache_creation: { ephemeral_1h_input_tokens: h1, ephemeral_5m_input_tokens: m5 },
        },
      },
    })
  const at = Date.parse('2026-11-13T18:00:00Z')
  expect(
    cacheFromTranscript(`cut-off-row"cache_\n${row('2026-11-13T17:00:00Z', 0, 0, 9)}\n${row('2026-11-13T18:00:00Z', 5, 0, 0)}\n`),
  ).toEqual({ at, ttlSeconds: 300 })
  expect(cacheFromTranscript(`${row('2026-11-13T17:00:00Z', 0, 0, 9)}\n${row('2026-11-13T18:00:00Z', 0, 700, 0)}`)).toEqual({
    at,
    ttlSeconds: 3600,
  })
  expect(cacheFromTranscript('{"type":"user"}')).toEqual({ at: undefined, ttlSeconds: undefined })
})

test('transcript paths flatten the working directory', () => {
  expect(transcriptPath('/Users/green/.claude', '/Users/green/nix-green', 'abc')).toBe(
    '/Users/green/.claude/projects/-Users-green-nix-green/abc.jsonl',
  )
})
