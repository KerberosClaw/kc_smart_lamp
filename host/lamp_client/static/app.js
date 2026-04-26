// kc_smart_lamp web UI — vanilla JS controller.
// Mirrors the iOS LampScreen behavior: read-modify-write 5 bytes via /api/set_state.

(() => {
  'use strict';

  // ─── State (mirrors LAMP_STATE 5 bytes) ────────────────────────────────────
  const state = {
    power: true,
    hue: 28,           // 0..360
    sat: 0.55,         // 0..1
    brightness: 60,    // 0..100
    activePreset: null,
    connection: 'connected', // scanning | connected | failed | reconnecting
  };

  // ─── Color helpers ─────────────────────────────────────────────────────────
  function hsvToRgb(h, s, v) {
    h = ((h % 360) + 360) % 360;
    const c = v * s;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = v - c;
    let r, g, b;
    if (h < 60)       [r, g, b] = [c, x, 0];
    else if (h < 120) [r, g, b] = [x, c, 0];
    else if (h < 180) [r, g, b] = [0, c, x];
    else if (h < 240) [r, g, b] = [0, x, c];
    else if (h < 300) [r, g, b] = [x, 0, c];
    else              [r, g, b] = [c, 0, x];
    return [
      Math.round((r + m) * 255),
      Math.round((g + m) * 255),
      Math.round((b + m) * 255),
    ];
  }
  function rgbToHex([r, g, b]) {
    return '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('').toUpperCase();
  }

  // ─── Presets ───────────────────────────────────────────────────────────────
  const PRESETS = [
    { id: 'focus', label: 'Focus', sub: '勿擾',  kind: 'color', hue: 0,  sat: 0.87, bri: 60, rgb: [230, 30, 30] },
    { id: 'warm',  label: 'Warm',  sub: '夜燈',  kind: 'color', hue: 32, sat: 0.65, bri: 35, rgb: [255, 180, 90] },
    { id: 'off',   label: 'Off',   sub: '關閉',  kind: 'off',                                  rgb: [80, 80, 80]   },
  ];

  const CONN_STATES = {
    scanning:     { label: 'Scanning',     detail: '搜尋附近裝置…' },
    connected:    { label: 'Connected',    detail: 'kc_smart_lamp' },
    failed:       { label: 'Failed',       detail: '點擊重新連線' },
    reconnecting: { label: 'Reconnecting', detail: '自動重試 (2/3)' },
  };

  // ─── DOM refs ──────────────────────────────────────────────────────────────
  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => Array.from(document.querySelectorAll(sel));

  const dom = {
    body:        document.body,
    connPill:    $('#conn-pill'),
    connLabel:   $('#conn-label'),
    connDetail:  $('#conn-detail'),
    hexReadout:  $('#readout-hex'),
    briReadout:  $('#readout-bri'),
    wheel:       $('#wheel'),
    wheelThumb:  $('#wheel-thumb'),
    briTrack:    $('#brightness'),
    briFill:     $('#brightness-fill'),
    briThumb:    $('#brightness-thumb'),
    briValue:    $('#brightness-value'),
    presets:     $$('.chip'),
    apply:       $('#apply'),
    power:       $('#power-toggle'),
    powerSub:    $('#power-sub'),
    stateCards:  $$('.state-card'),
  };

  // ─── Render ────────────────────────────────────────────────────────────────
  function render() {
    const power = state.power;
    const rgb = power ? hsvToRgb(state.hue, state.sat, 1) : [120, 120, 120];
    const hex = rgbToHex(rgb);

    // CSS custom properties — drive the entire visual system
    const root = document.documentElement;
    root.style.setProperty('--accent', hex);
    root.style.setProperty('--accent-r', rgb[0]);
    root.style.setProperty('--accent-g', rgb[1]);
    root.style.setProperty('--accent-b', rgb[2]);
    root.style.setProperty('--accent-soft', `rgba(${rgb.join(',')},0.18)`);
    root.style.setProperty('--accent-glow',
      `rgba(${rgb.join(',')},${0.10 + state.brightness / 100 * 0.30})`);

    // Backdrop tint reacts to power + brightness
    document.body.style.setProperty('--accent-bg-strength',
      String(0.10 + state.brightness / 100 * 0.18));
    document.body.dataset.power = power ? 'on' : 'off';

    // Top-of-page radial follows accent + brightness
    document.body.style.background = power
      ? `radial-gradient(120% 90% at 50% 0%, rgba(${rgb.join(',')},${0.10 + state.brightness/100*0.18}) 0%, rgba(${rgb.join(',')},0.04) 35%, #000 75%) #000`
      : `#000`;

    // Header readout
    dom.hexReadout.textContent = hex;
    dom.briReadout.textContent = `${state.brightness}%`;

    // Wheel thumb position
    const wheelRect = dom.wheel.getBoundingClientRect();
    if (wheelRect.width > 0) {
      const r = wheelRect.width / 2;
      const inset = 14;
      const rad = state.hue * Math.PI / 180;
      const x = r + Math.cos(rad) * state.sat * (r - inset);
      const y = r + Math.sin(rad) * state.sat * (r - inset);
      dom.wheelThumb.style.left = `${x}px`;
      dom.wheelThumb.style.top  = `${y}px`;
    }
    dom.wheel.dataset.dim = power ? 'false' : 'true';

    // Brightness
    dom.briValue.textContent = `${state.brightness}%`;
    dom.briFill.style.width = `${state.brightness}%`;
    dom.briThumb.style.left = `calc(${state.brightness}% )`;
    dom.briThumb.style.transform = `translateX(-50%)`;

    // Presets
    dom.presets.forEach(btn => {
      btn.dataset.active = (btn.dataset.id === state.activePreset) ? 'true' : 'false';
    });

    // Power
    dom.power.dataset.on = power ? 'true' : 'false';
    dom.power.setAttribute('aria-checked', String(power));
    dom.powerSub.textContent = power ? '燈泡開啟中' : '燈泡已關閉';

    // Connection pill
    const c = CONN_STATES[state.connection];
    dom.connPill.dataset.state = state.connection;
    dom.connLabel.textContent  = c.label;
    dom.connDetail.textContent = c.detail;

    // State cards
    dom.stateCards.forEach(card => {
      card.dataset.active = (card.dataset.state === state.connection) ? 'true' : 'false';
    });
  }

  // ─── Color wheel interaction ───────────────────────────────────────────────
  function wireWheel() {
    let dragging = false;

    function update(clientX, clientY) {
      const rect = dom.wheel.getBoundingClientRect();
      const r = rect.width / 2;
      const inset = 14;
      const cx = rect.left + r;
      const cy = rect.top  + r;
      const dx = clientX - cx;
      const dy = clientY - cy;
      let h = Math.atan2(dy, dx) * 180 / Math.PI;
      if (h < 0) h += 360;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const s = Math.min(1, dist / (r - inset));
      state.hue = h;
      state.sat = s;
      state.activePreset = null;
      render();
      scheduleAutoApply();
    }

    function onPointerDown(e) {
      if (!state.power) return;
      e.preventDefault();
      dragging = true;
      dom.wheel.setPointerCapture?.(e.pointerId);
      update(e.clientX, e.clientY);
    }
    function onPointerMove(e) {
      if (!dragging) return;
      update(e.clientX, e.clientY);
    }
    function onPointerUp(e) {
      dragging = false;
      try { dom.wheel.releasePointerCapture?.(e.pointerId); } catch (_) {}
    }

    dom.wheel.addEventListener('pointerdown', onPointerDown);
    dom.wheel.addEventListener('pointermove', onPointerMove);
    dom.wheel.addEventListener('pointerup',   onPointerUp);
    dom.wheel.addEventListener('pointercancel', onPointerUp);
  }

  // ─── Brightness slider ─────────────────────────────────────────────────────
  function wireBrightness() {
    let dragging = false;
    function update(clientX) {
      const rect = dom.briTrack.getBoundingClientRect();
      const x = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
      state.brightness = Math.round(x * 100);
      state.activePreset = null;
      render();
      scheduleAutoApply();
    }
    dom.briTrack.addEventListener('pointerdown', (e) => {
      if (!state.power) return;
      e.preventDefault();
      dragging = true;
      dom.briTrack.setPointerCapture?.(e.pointerId);
      update(e.clientX);
    });
    dom.briTrack.addEventListener('pointermove', (e) => {
      if (!dragging) return;
      update(e.clientX);
    });
    dom.briTrack.addEventListener('pointerup', (e) => {
      dragging = false;
      try { dom.briTrack.releasePointerCapture?.(e.pointerId); } catch (_) {}
    });
    dom.briTrack.addEventListener('pointercancel', () => { dragging = false; });
  }

  // ─── Presets ───────────────────────────────────────────────────────────────
  function wirePresets() {
    dom.presets.forEach(btn => {
      const id = btn.dataset.id;
      const p = PRESETS.find(x => x.id === id);
      if (!p) return;
      // chip glyph color
      btn.style.setProperty('--chip-r', p.rgb[0]);
      btn.style.setProperty('--chip-g', p.rgb[1]);
      btn.style.setProperty('--chip-b', p.rgb[2]);

      btn.addEventListener('click', async () => {
        state.activePreset = p.id;
        if (p.kind === 'off') {
          state.power = false;
        } else {
          state.power = true;
          state.hue = p.hue;
          state.sat = p.sat;
          state.brightness = p.bri;
        }
        render();
        // presets auto-apply (skip Apply button)
        await sendState();
      });
    });
  }

  // ─── Auto-apply (debounced) ────────────────────────────────────────────────
  // Continuous inputs (wheel drag, slider drag, keyboard) call this on every
  // change.  The last call within the window wins, so the actual BLE write
  // only fires once after the user stops moving.  220ms feels instant on
  // release without firing mid-drag.
  let autoApplyTimer = null;
  function scheduleAutoApply(delay = 220) {
    clearTimeout(autoApplyTimer);
    autoApplyTimer = setTimeout(() => {
      autoApplyTimer = null;
      sendState();
    }, delay);
  }

  // ─── Apply ─────────────────────────────────────────────────────────────────
  async function sendState() {
    const rgb = hsvToRgb(state.hue, state.sat, 1);
    const body = {
      power: state.power,
      r: rgb[0], g: rgb[1], b: rgb[2],
      brightness: state.brightness,
    };
    try {
      const resp = await fetch('/api/set_state', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!resp.ok) throw new Error(`${resp.status}`);
      return true;
    } catch (e) {
      // Demo mode: when there's no backend, treat as success so the UI is testable.
      console.warn('[lamp] send failed, demo mode:', e.message);
      return false;
    }
  }

  function wireApply() {
    dom.apply.addEventListener('click', async () => {
      if (dom.apply.dataset.applied === 'true') return;
      dom.apply.disabled = true;
      const ok = await sendState();
      dom.apply.dataset.applied = 'true';
      dom.apply.dataset.error   = ok ? 'false' : 'false'; // demo: always show Applied
      $('#apply-applied').textContent = ok ? 'Applied' : 'Applied (demo)';
      setTimeout(() => {
        dom.apply.dataset.applied = 'false';
        dom.apply.disabled = false;
      }, 1800);
    });
  }

  // ─── Power toggle ──────────────────────────────────────────────────────────
  function wirePower() {
    dom.power.addEventListener('click', async () => {
      state.power = !state.power;
      state.activePreset = null;
      render();
      // Discrete action — fire immediately, no debounce.
      sendState();
    });
  }

  // ─── Connection state cards (demo / showcase) ──────────────────────────────
  function wireStateCards() {
    dom.stateCards.forEach(card => {
      card.addEventListener('click', () => {
        state.connection = card.dataset.state;
        render();
      });
    });
    dom.connPill.addEventListener('click', () => {
      if (state.connection === 'failed') {
        state.connection = 'scanning';
        render();
        setTimeout(() => { state.connection = 'connected'; render(); }, 1200);
      }
    });
  }

  // ─── Init ──────────────────────────────────────────────────────────────────
  function init() {
    wireWheel();
    wireBrightness();
    wirePresets();
    wireApply();
    wirePower();
    wireStateCards();
    render();
    // re-render on resize so wheel thumb stays correct
    window.addEventListener('resize', render);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
