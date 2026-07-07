/**
 * WeightNest 算法测试共享核心 — test_algorithm_core.js
 *
 * 所有算法逐行复刻 weight_math.dart + weight_plugin.dart + alert_service.dart。
 * 两个测试工具 (weightnest_algorithm_test_tool.html, alert_algorithm_test_tool.html) 共享此文件。
 *
 * 更新规则：Dart 源码变更时，同步更新本文件的对应函数。不要在两份 HTML 里各改一份。
 */

// ==================== 常量（复刻 weight_math.dart） ====================

const WN = {
  WARNING_DEVIATION_PCT: 10.0,
  DANGER_DEVIATION_PCT: 15.0,
  OVERDUE_WARNING_MULTIPLIER: 1.5,
  OVERDUE_DANGER_MULTIPLIER: 3.0,
  CHRONIC_TREND_PCT: 7.0,
  CHICK_GROWTH_HEALTHY_RATE: 0.08,
  CHICK_GROWTH_SLOW_RATE: 0.03,
  WEANING_WARNING_DROP_PCT: 10.0,
  WEANING_DANGER_DROP_PCT: 15.0,
  ANALYSIS_WINDOW_DAYS: 90,
  EWMA_ALPHA: 0.2,
};

// ==================== 纯数学工具（复刻 weight_math.dart） ====================

/** Log 增长率 ln(curr / prev)。任一 ≤0 时安全返回 0。 */
function logGrowth(prev, curr) {
  return prev > 0 && curr > 0 ? Math.log(curr / prev) : 0;
}

/** 标准化为 24 小时增长率。h ≤ 0 时返回原值（不做外推）。 */
function normalize24h(rate, h) {
  return h > 0 ? rate * (24 / h) : rate;
}

/** 两个时刻之间的小时数。 */
function hoursBetween(a, b) {
  return (b - a) / 3600000;
}

/** 算术平均。调用方保证列表非空。 */
function avg(arr) {
  return arr.reduce((a, b) => a + b, 0) / arr.length;
}

/**
 * EWMA 指数移动平均序列，默认 alpha=0.2（基线平滑）。
 * 空列表返回 []，单元素返回自身。
 */
function ewma(values, alpha) {
  if (alpha === undefined) alpha = WN.EWMA_ALPHA;
  if (!values.length) return [];
  const r = [values[0]];
  for (let i = 1; i < values.length; i++) {
    r.push(values[i] * alpha + r[r.length - 1] * (1 - alpha));
  }
  return r;
}

// ==================== 生长阶段 & 有效间隔（复刻 bird_repository.dart:264） ====================

/**
 * 计算有效称重间隔（天）：鸟级覆盖优先，否则按生长阶段取物种默认。
 * 复刻 computeEffectiveWeighInterval()。
 */
function computeEffectiveInterval(birdOverrideDays, species, ageDays) {
  if (birdOverrideDays != null && birdOverrideDays > 0) return birdOverrideDays;
  if (ageDays <= species.nestlingEndDays) return species.nestlingWeighIntervalDays;
  if (ageDays <= species.juvenileEndDays) return species.juvenileWeighIntervalDays;
  return species.adultWeighIntervalDays;
}

/** 生长阶段（中文）。 */
function growthStage(ageDays, species) {
  if (ageDays <= species.nestlingEndDays) return '雏鸟';
  if (ageDays <= species.juvenileEndDays) return '幼鸟';
  return '成鸟';
}

// ==================== 鸟/体重工厂 ====================

/** 构建物种对象。 */
function makeSpecies(overrides) {
  return Object.assign({
    nestlingEndDays: 45,
    juvenileEndDays: 120,
    nestlingWeighIntervalDays: 1,
    juvenileWeighIntervalDays: 3,
    adultWeighIntervalDays: 7,
  }, overrides);
}

/** 构建鸟对象。 */
function makeBird(overrides) {
  return Object.assign({
    ageDays: 30,
    birdOverride: 0,        // 0 = 使用物种默认
    manualBaselineG: 0,     // 0 = 使用 EWMA 自动基线
    weaningOverride: null,  // null = 自动检测
    species: makeSpecies(),
  }, overrides);
}

/** 构建体重记录 {g, ts}，ts 为 Date 或毫秒时间戳。 */
function makeWeight(g, ts) {
  return { g: g, ts: ts instanceof Date ? ts.getTime() : ts };
}

// ==================== 断奶期检测（复刻 isWeaningPhase） ====================

/**
 * 判断是否处于断奶期（手动覆盖优先，否则自动检测）。
 * weights 需按 recordedAt ASC（最早在前），每项含 {g, ts}。
 * 返回 {result: bool, reason: string}。
 */
function isWeaningPhase(bird, weightsAsc) {
  if (bird.weaningOverride === true) return { result: true, reason: '手动覆盖：强制进入断奶期' };
  if (bird.weaningOverride === false) return { result: false, reason: '手动覆盖：强制退出断奶期' };

  const species = bird.species;
  if (bird.ageDays < species.nestlingEndDays - 5 || bird.ageDays > species.juvenileEndDays) {
    if (bird.ageDays > species.juvenileEndDays) return { result: false, reason: `日龄 ${bird.ageDays}天 > juvenileEnd=${species.juvenileEndDays}天，超出断奶窗口上限` };
    return { result: false, reason: `日龄 ${bird.ageDays}天 < nestlingEnd-5=${species.nestlingEndDays - 5}天，尚未进入断奶窗口` };
  }
  if (weightsAsc.length < 3) return { result: false, reason: `仅有 ${weightsAsc.length} 条体重记录，需 ≥3 条方可判定` };

  const grams = weightsAsc.map(w => w.g);
  const peak = Math.max(...grams);
  const latest = grams[grams.length - 1];
  if (latest >= peak * 0.95) return { result: false, reason: `最新体重 ${latest.toFixed(1)}g ≥ 峰值 ${peak.toFixed(1)}g × 95%，尚未明显下降` };

  let recentDrops = 0;
  for (let i = weightsAsc.length - 1; i > 0 && i > weightsAsc.length - 4; i--) {
    if (grams[i] < grams[i - 1]) recentDrops++;
  }
  if (recentDrops < 2) return { result: false, reason: `最近3次中仅 ${recentDrops} 次下降，需 ≥2 次方进入断奶` };

  // 自动退出条件
  if (bird.ageDays > species.juvenileEndDays + 10) return { result: false, reason: `日龄 ${bird.ageDays}天 > juvenileEnd+10=${species.juvenileEndDays + 10}天，超龄强制退出` };

  if (weightsAsc.length >= 3) {
    const last3 = weightsAsc.slice(-3).map(w => w.g);
    const avg3 = avg(last3);
    const range = Math.max(...last3) - Math.min(...last3);
    if (range / avg3 * 100 < 3 && last3[last3.length - 1] >= last3[0]) return { result: false, reason: `最近3次体重企稳（波动 ${(range / avg3 * 100).toFixed(1)}% < 3%），自动退出断奶` };
  }

  const subset = weightsAsc.slice(Math.floor(weightsAsc.length * 2 / 3));
  const weaningMin = Math.min(...subset.map(w => w.g));
  if (latest > weaningMin * 1.05) return { result: false, reason: `体重回升至 ${latest.toFixed(1)}g > 断奶最低 ${weaningMin.toFixed(1)}g × 1.05，自动退出断奶` };

  return { result: true, reason: '自动进入：从峰值下降 >5% 且近3次 ≥2次下降' };
}

// ==================== 告警子检测（复刻 weight_plugin.dart） ====================

/** _weaningAlerts — weightsAsc 按 recordedAt ASC */
function weaningAlerts(bird, weightsAsc) {
  const grams = weightsAsc.map(w => w.g);
  const peak = Math.max(...grams);
  const latest = grams[grams.length - 1];
  const dropPct = (peak - latest) / peak * 100;
  const alerts = [];

  if (dropPct > WN.WEANING_DANGER_DROP_PCT) {
    alerts.push({ type: '断奶期体重下降过多', severity: 'danger', desc: `从峰值 ${peak.toFixed(1)}g 下降 ${dropPct.toFixed(1)}%，超出正常范围，建议检查` });
  } else if (dropPct > WN.WEANING_WARNING_DROP_PCT) {
    alerts.push({ type: '断奶期体重下降', severity: 'warning', desc: `从峰值 ${peak.toFixed(1)}g 下降 ${dropPct.toFixed(1)}%，属正常范围` });
  }
  return alerts;
}

/** _chickGrowth — weightsAsc 按 recordedAt ASC，每项含 {g, ts}（ts = Date 或 ms）。 */
function chickGrowth(bird, weightsAsc) {
  if (weightsAsc.length < 2) return [];
  const now = Date.now();
  // ponytail: 对齐 Dart isAfter(cutoff.subtract(Duration(seconds:1))) — 即 ts >= cutoff - 1s，包含恰好 48h 的边界点
  const cutoff48h = now - 48 * 3600000 - 1000;
  const recent = weightsAsc.filter(w => w.ts > cutoff48h);
  if (recent.length < 2) return [];

  const rates = [];
  for (let i = 1; i < recent.length; i++) {
    const h = hoursBetween(recent[i - 1].ts, recent[i].ts);
    if (h <= 0) continue;
    rates.push(normalize24h(logGrowth(recent[i - 1].g, recent[i].g), h));
  }
  if (!rates.length) return [];

  const avgRate = avg(rates);
  const alerts = [];

  // 连续下降（遍历全部 weights，不只是 recent — 复刻 Dart 行为）
  let consecDrop = 0;
  const allGrams = weightsAsc.map(w => w.g);
  for (let i = 1; i < allGrams.length; i++) {
    if (allGrams[i] < allGrams[i - 1]) consecDrop++;
    else consecDrop = 0;
  }

  const firstW = recent[0].g;
  const lastW = recent[recent.length - 1].g;
  const displayPct = (lastW - firstW) / firstW * 100;
  let hasDropAlert = false;

  if (avgRate > WN.CHICK_GROWTH_HEALTHY_RATE) {
    // 正常 — 不生成告警
  } else if (avgRate > WN.CHICK_GROWTH_SLOW_RATE) {
    alerts.push({ type: '增长减缓', severity: 'warning', desc: `48h 仅增重 ${displayPct.toFixed(1)}%，增长偏慢` });
  } else if (avgRate > 0) {
    alerts.push({ type: '增长停滞', severity: 'danger', desc: `48h 仅增重 ${displayPct.toFixed(1)}%，接近停滞` });
  } else {
    hasDropAlert = true;
    alerts.push({ type: '体重下降', severity: 'danger', desc: `48h 下降 ${Math.abs(displayPct).toFixed(1)}%` });
  }

  // Step B：最后一对独立检查
  if (!hasDropAlert && rates.length) {
    const lastRate = rates[rates.length - 1];
    if (lastRate < -0.05) {
      const prev = recent[recent.length - 2].g;
      const curr = recent[recent.length - 1].g;
      const dropPct = (prev - curr) / prev * 100;
      alerts.push({ type: '体重下降', severity: lastRate < -0.15 ? 'danger' : 'warning', desc: `较上次下降 ${dropPct.toFixed(1)}%（48h平均正常，近期下降值得关注）` });
    }
  }

  // Step C：连续下降
  if (consecDrop >= 3) {
    alerts.push({ type: '连续下降', severity: consecDrop >= 4 ? 'danger' : 'warning', desc: `连续 ${consecDrop} 次体重下降` });
  }

  return alerts;
}

/** _baselineAlerts — weightsAsc 按 recordedAt ASC。 */
function baselineAlerts(bird, weightsAsc) {
  const alerts = [];
  const grams = weightsAsc.map(w => w.g);
  const emaVals = ewma(grams);
  const emaBaseline = emaVals[emaVals.length - 1];
  const baseline = bird.manualBaselineG > 0 ? bird.manualBaselineG : emaBaseline;
  const latest = grams[grams.length - 1];
  const deviation = (latest - baseline) / baseline * 100;

  // 维度 A：单点偏离基线（急性）
  if (Math.abs(deviation) > WN.DANGER_DEVIATION_PCT) {
    const dir = deviation > 0 ? '偏高' : '偏低';
    alerts.push({ type: `体重异常${dir}`, severity: 'danger', desc: `当前 ${latest.toFixed(1)}g，较基线 ${baseline.toFixed(1)}g ${dir} ${Math.abs(deviation).toFixed(0)}%（${deviation > 0 ? '可能为产蛋、过肥或疾病' : '值得关注'}）` });
  } else if (Math.abs(deviation) > WN.WARNING_DEVIATION_PCT) {
    const dir = deviation > 0 ? '偏高' : '偏低';
    alerts.push({ type: `体重${dir}`, severity: 'warning', desc: `当前 ${latest.toFixed(1)}g，较基线 ${baseline.toFixed(1)}g ${dir} ${Math.abs(deviation).toFixed(0)}%` });
  }

  // 维度 B：基线持续趋势（慢性）
  if (grams.length >= 4) {
    const emaSnapshots = ewma(grams);
    const recentN = Math.max(2, Math.min(Math.ceil(emaSnapshots.length / 3), emaSnapshots.length - 1));
    const earlyBaseline = emaSnapshots[emaSnapshots.length - 1 - recentN];
    const currentBaseline = emaSnapshots[emaSnapshots.length - 1];
    const trend = (currentBaseline - earlyBaseline) / earlyBaseline * 100;
    if (trend < -WN.CHRONIC_TREND_PCT) {
      alerts.push({ type: '体重持续下降', severity: 'warning', desc: `基线从 ${earlyBaseline.toFixed(1)}g 降至 ${currentBaseline.toFixed(1)}g（${Math.abs(trend).toFixed(0)}%），持续下行值得关注` });
    } else if (trend > WN.CHRONIC_TREND_PCT) {
      alerts.push({ type: '体重持续上升', severity: 'warning', desc: `基线从 ${earlyBaseline.toFixed(1)}g 升至 ${currentBaseline.toFixed(1)}g（${trend.toFixed(0)}%），可能为过肥或非繁育增重` });
    }
  }

  return alerts;
}

/** _overdue — weightsAsc 按 recordedAt ASC。若为空数组 → 90天兜底。 */
function overdue(bird, weightsAsc) {
  if (!weightsAsc.length) {
    return [{ type: '超期未称重', severity: 'warning', desc: '超过90天未记录体重，请尽快称重（安全网：interval≤0 的鸟也被此捕获）' }];
  }
  const latestDate = weightsAsc[weightsAsc.length - 1].ts;
  const daysSince = Math.floor((Date.now() - latestDate) / 86400000);
  const interval = computeEffectiveInterval(bird.birdOverride, bird.species, bird.ageDays);
  if (interval <= 0) return [];

  if (daysSince > interval * WN.OVERDUE_DANGER_MULTIPLIER) {
    return [{ type: '超期未称重', severity: 'danger', desc: `已 ${daysSince} 天未记录体重（间隔 ${interval}天），严重超期` }];
  }
  if (daysSince > interval * WN.OVERDUE_WARNING_MULTIPLIER) {
    return [{ type: '超期未称重', severity: 'warning', desc: `已 ${daysSince} 天未记录体重（间隔 ${interval}天）` }];
  }
  return [];
}

// ==================== isLatestAbnormal / isLatestAbnormalDirection ====================

/**
 * 判断最近一次称重的异常方向。
 * weights 按 recordedAt DESC（最新在前），每项含 {g, ts}。
 * 返回 'none' | 'high' | 'low'。
 */
function isLatestAbnormalDirection(bird, weightsDesc) {
  if (weightsDesc.length < 2) return 'none';
  const latest = weightsDesc[0].g;

  // 断奶期 → low（从峰值下降）
  const stage = growthStage(bird.ageDays, bird.species);
  const inWeaning = stage === '雏鸟' && isWeaningPhase(bird, [...weightsDesc].reverse()).result;
  if (inWeaning) {
    const peak = Math.max(...weightsDesc.map(w => w.g));
    const drop = (peak - latest) / peak * 100;
    return drop > WN.WEANING_WARNING_DROP_PCT ? 'low' : 'none';
  }

  switch (stage) {
    case '雏鸟': {
      const now = Date.now();
      const cutoff48h = now - 48 * 3600000;
      const recent = weightsDesc.filter(w => w.ts > cutoff48h);
      if (recent.length < 2) return 'none';
      const asc = [...recent].reverse();
      const rates = [];
      for (let i = 1; i < asc.length; i++) {
        const h = hoursBetween(asc[i - 1].ts, asc[i].ts);
        if (h <= 0) continue;
        if (asc[i - 1].g > 0 && asc[i].g > 0) {
          rates.push(normalize24h(Math.log(asc[i].g / asc[i - 1].g), h));
        }
      }
      if (!rates.length) return 'none';
      const avgRate = avg(rates);
      if (avgRate < WN.CHICK_GROWTH_SLOW_RATE) return 'low';
      return 'none';
    }
    case '幼鸟':
    case '成鸟': {
      const manualB = bird.manualBaselineG;
      let baseline;
      if (manualB > 0) {
        baseline = manualB;
      } else {
        if (weightsDesc.length < 3) return 'none';
        const values = [...weightsDesc].reverse().map(w => w.g);
        let ema = values[0];
        for (let i = 1; i < values.length; i++) {
          ema = 0.2 * values[i] + 0.8 * ema;
        }
        baseline = ema;
      }
      const deviation = (latest - baseline) / baseline * 100;
      if (Math.abs(deviation) <= WN.WARNING_DEVIATION_PCT) return 'none';
      return deviation > 0 ? 'high' : 'low';
    }
  }
  return 'none';
}

function isLatestAbnormal(bird, weightsDesc) {
  return isLatestAbnormalDirection(bird, weightsDesc) !== 'none';
}

// ==================== detectAll（复刻 alert_service.dart + weight_plugin.dart） ====================

/**
 * 聚合检测。weightsAsc 按 recordedAt ASC。
 * 若 weightsAsc 为空 → 90天兜底告警。
 */
function detectAll(bird, weightsAsc) {
  if (!weightsAsc.length) {
    return [{ type: '超期未称重', severity: 'warning', desc: '超过90天未记录体重，请尽快称重' }];
  }

  const stage = growthStage(bird.ageDays, bird.species);

  // 断奶期分支
  if (stage === '雏鸟' && isWeaningPhase(bird, weightsAsc).result) {
    return weaningAlerts(bird, weightsAsc);
  }

  let alerts = [];
  switch (stage) {
    case '雏鸟': alerts.push(...chickGrowth(bird, weightsAsc)); break;
    case '幼鸟': case '成鸟': alerts.push(...baselineAlerts(bird, weightsAsc)); break;
  }
  alerts.push(...overdue(bird, weightsAsc));
  return alerts;
}

// ==================== 任务生成算法（复刻 weight_plugin.dart detectTasks） ====================

/**
 * 判定今日任务状态。
 * 返回 {status: 'todo'|'done'|'skip', reason: string, interval: int, stage: string}
 */
function determineTaskStatus(bird, daysSinceLast) {
  const interval = computeEffectiveInterval(bird.birdOverride, bird.species, bird.ageDays);
  const stage = growthStage(bird.ageDays, bird.species);

  if (interval <= 0) {
    return { status: 'skip', reason: 'intervalDays ≤ 0，跳过该鸟', interval, stage };
  }
  // ponytail: daysSinceLast === null 表示从未称重
  if (daysSinceLast === null || daysSinceLast === undefined) {
    return { status: 'todo', reason: '从未称重，生成"待完成"任务', interval, stage };
  }
  if (daysSinceLast >= interval) {
    return { status: 'todo', reason: `距上次${daysSinceLast}天 ≥ 间隔${interval}天，生成"待完成"任务`, interval, stage };
  }
  return { status: 'done', reason: `距上次${daysSinceLast}天 < 间隔${interval}天，生成"已完成"历史记录`, interval, stage };
}

// ==================== UI 渲染工具 ====================

function renderBadge(text, cls) {
  return `<span class="badge badge-${cls}">${text}</span>`;
}

function renderOkBox(title, desc) {
  return `<div class="ok-box"><div class="ok-title">✅ ${title}</div>${desc ? `<div class="ok-desc">${desc}</div>` : ''}</div>`;
}

function renderConflictBox(title, desc) {
  return `<div class="conflict-box"><div class="conflict-title">❌ ${title}</div><div class="conflict-desc">${desc}</div></div>`;
}

function renderAlerts(alertList) {
  if (!alertList.length) return '';
  return alertList.map(a => {
    const sevCls = a.severity === 'danger' ? 'danger-item' : 'warn';
    const ico = a.severity === 'danger' ? '🔴' : '🟡';
    return `<div class="alert-item ${sevCls}">
      <span class="alert-icon">${ico}</span>
      <div class="alert-text">
        <div class="alert-title">${a.type} ${renderBadge(a.severity === 'danger' ? 'danger' : 'warning', a.severity === 'danger' ? 'badge-danger' : 'badge-warning')}</div>
        <div class="alert-desc">${a.desc}</div>
      </div>
    </div>`;
  }).join('');
}

// ==================== Chart 工具 ====================

const _chartInstances = {};

function destroyChart(id) {
  if (_chartInstances[id]) { _chartInstances[id].destroy(); delete _chartInstances[id]; }
}

function makeLineChart(canvasId, labels, datasets, yBeginAtZero) {
  destroyChart(canvasId);
  const ctx = document.getElementById(canvasId);
  if (!ctx) return null;
  _chartInstances[canvasId] = new Chart(ctx, {
    type: 'line',
    data: { labels, datasets },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true, position: 'top',
          labels: { font: { size: 11 }, boxWidth: 12, padding: 10, usePointStyle: true, pointStyleWidth: 10 },
        },
        tooltip: {
          backgroundColor: 'rgba(0,0,0,0.78)', titleFont: { size: 11 }, bodyFont: { size: 11 },
          padding: 8, cornerRadius: 6, displayColors: true, boxWidth: 8,
        },
      },
      scales: {
        y: { beginAtZero: !!yBeginAtZero, ticks: { font: { size: 11 } }, grid: { color: 'rgba(0,0,0,0.06)' } },
        x: { ticks: { font: { size: 11 }, maxRotation: 0 }, grid: { display: false } },
      }
    }
  });
  return _chartInstances[canvasId];
}

// ==================== 预设管理（localStorage） ====================

const PRESET_PREFIX = 'wn_preset_';

function savePreset(name, data) {
  const key = PRESET_PREFIX + name;
  localStorage.setItem(key, JSON.stringify({ savedAt: new Date().toISOString(), ...data }));
  return key;
}

function loadPreset(name) {
  const raw = localStorage.getItem(PRESET_PREFIX + name);
  return raw ? JSON.parse(raw) : null;
}

function listPresets() {
  const names = [];
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i);
    if (k.startsWith(PRESET_PREFIX)) names.push(k.slice(PRESET_PREFIX.length));
  }
  return names.sort();
}

function deletePreset(name) {
  localStorage.removeItem(PRESET_PREFIX + name);
}

// ==================== 日志 ====================

const _logEntries = [];

function log(level, msg) {
  const entry = { ts: new Date().toISOString(), level, msg };
  _logEntries.push(entry);
  // 只保留最近 500 条
  if (_logEntries.length > 500) _logEntries.shift();
  return entry;
}

function getLogs() { return [..._logEntries]; }
function clearLogs() { _logEntries.length = 0; }

// ==================== 批量测试运行器 ====================

/**
 * 运行一组测试用例。
 * 每个用例: {name, setup(), expected: string[] (告警type列表，[]=无告警), bird?, weightsAsc?}
 * setup() 应设置 bird 和 weightsAsc 到 this 上下文，或直接返回 {bird, weightsAsc}。
 *
 * 返回 [{name, pass, expected, actual, durationMs, error}]
 */
function runBatch(cases) {
  const results = [];
  for (const c of cases) {
    const t0 = performance.now();
    let error = null;
    let actual = null;
    try {
      const ctx = c.setup();
      const bird = ctx.bird || c.bird;
      const weightsAsc = ctx.weightsAsc || c.weightsAsc;
      if (!bird) throw new Error('测试用例缺少 bird');
      actual = detectAll(bird, weightsAsc || []).map(a => a.type);
    } catch (e) {
      error = e.message || String(e);
    }
    const t1 = performance.now();
    const expected = c.expected || [];
    const pass = !error && JSON.stringify([...actual].sort()) === JSON.stringify([...expected].sort());
    results.push({
      name: c.name,
      pass,
      expected,
      actual: actual || [],
      durationMs: +(t1 - t0).toFixed(2),
      error,
    });
    log(pass ? 'pass' : 'fail', `${c.name} — ${pass ? '✅' : '❌'} (${(t1 - t0).toFixed(1)}ms)`);
  }
  return results;
}

/**
 * 渲染批量结果表格到 containerId。
 */
function renderBatchResults(containerId, results) {
  const passed = results.filter(r => r.pass).length;
  const failed = results.filter(r => !r.pass).length;
  const totalMs = results.reduce((s, r) => s + r.durationMs, 0);

  let html = `<div style="margin-bottom:8px;font-size:12px;">批量测试结果：<span style="color:var(--color-text-success);">${passed} 通过</span> / <span style="color:var(--color-text-danger);">${failed} 失败</span> / ${results.length} 总计 · ${totalMs.toFixed(1)}ms</div>`;
  html += '<table>';
  html += '<thead><tr><th>#</th><th>用例</th><th>期望</th><th>实际</th><th style="text-align:center;">结果</th><th style="text-align:right;">耗时</th></tr></thead><tbody>';
  results.forEach((r, i) => {
    const rowCls = !r.pass ? ' class="batch-row-fail"' : '';
    html += `<tr${rowCls}>
      <td>${i + 1}</td>
      <td>${r.name}</td>
      <td>${r.expected.length ? r.expected.join(', ') : '—'}</td>
      <td>${r.error ? `<span style="color:var(--color-text-danger);">ERROR: ${r.error}</span>` : (r.actual.length ? r.actual.join(', ') : '—')}</td>
      <td style="text-align:center;">${r.pass ? '✅' : '❌'}</td>
      <td style="text-align:right;">${r.durationMs}ms</td>
    </tr>`;
  });
  html += '</tbody></table>';
  document.getElementById(containerId).innerHTML = html;
}

// ==================== 导出 ====================

function exportJSON(data, filename) {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  downloadBlob(blob, filename || 'test_results.json');
}

function exportCSV(rows, filename) {
  if (!rows.length) return;
  const headers = Object.keys(rows[0]);
  const csv = [headers.join(','), ...rows.map(r => headers.map(h => JSON.stringify(r[h] != null ? String(r[h]) : '')).join(','))].join('\n');
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' }); // BOM for Excel
  downloadBlob(blob, filename || 'test_results.csv');
}

function downloadBlob(blob, filename) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(a.href);
}
