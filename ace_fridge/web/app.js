// anim_core · supplement shop page. Pure renderer: Lua owns the state and
// pushes {action:'shop:state', data} — as a JSON string via SendDuiMessage on
// the hologram, or as an object via the ui_page iframe host. Nothing is ever
// sent back (a DUI has no callback channel), so there are no handlers here.
const ROW = 54;                 // must match --row in style.css
const LIST_TOP = 40, LIST_BOTTOM = 40, STAGE_H = 640;
const MID = (STAGE_H - LIST_TOP - LIST_BOTTOM) / 2;   // middle of the list area

const COLOR = { stamina: '#3ddc84', speed: '#4aa8ff', strength: '#ff5e5e', combat: '#b96bff', lung_capacity: '#35e0e0', exh: '#6fc3ff' };
const GLYPH = {
  gain:  '<svg viewBox="0 0 24 24"><path d="M13 2 3 14h7l-1 8 10-12h-7z"/></svg>',
  decay: '<svg viewBox="0 0 24 24"><path d="M6 2h12v3l-5 7 5 7v3H6v-3l5-7-5-7z"/></svg>',
  exh:   '<svg viewBox="0 0 24 24"><path d="M12 2s-6.5 7.5-6.5 12.5a6.5 6.5 0 0 0 13 0C18.5 9.5 12 2 12 2z"/></svg>',
};

function esc(s) { return String(s).replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }

function icons(list) {
  return (list || []).map(e => {
    const kind = e.k === 'exh' ? 'exh' : (e.k === 'decay' ? 'decay' : 'gain');
    const color = COLOR[kind === 'exh' ? 'exh' : e.s] || '#999';
    return `<span class="ic ${kind}" style="--c:${color}">${GLYPH[kind]}</span>`;
  }).join('');
}

let lastFlash = null;

function render(d) {
  const items = d.items || [];
  const cur = (d.currency === undefined || d.currency === null) ? '$' : String(d.currency);
  document.documentElement.style.setProperty('--sc', d.scale || 1);
  let sel = Math.max(0, items.findIndex(it => it.selected));
  const flash = d.flashId && d.flashId !== lastFlash;   // one purchase confirmation per push that carries it
  if (flash) lastFlash = d.flashId;
  const track = document.getElementById('track');
  track.innerHTML = items.map((it, i) => {
    const dist = Math.abs(i - sel);
    const op = i === sel ? 1 : Math.max(0.18, 1 - 0.26 * dist);
    if (it.cancel) {
      return `
    <div class="row cancel${i === sel ? ' sel' : ''}" style="opacity:${op}">
      <span class="dot"></span>
      <span class="name">${esc(it.label)}</span>
    </div>`;
    }
    return `
    <div class="row${i === sel ? ' sel' : ''}${flash && i === sel ? ' bought' : ''}" style="opacity:${op}">
      <span class="dot"></span>
      <span class="name">${esc(it.label)}</span>
      <span class="icons">${icons(it.effects)}</span>
      <span class="bag">${it.inBag > 0 ? esc(String(it.inBag)) + ' <i class="fa-solid fa-bag-shopping"></i>' : ''}</span>
      <span class="price">${cur === '' ? '' : esc(cur)}${esc(String(it.price))}</span>
      <span class="tick"><i class="fa-solid fa-check"></i></span>
    </div>`;
  }).join('');
  // keep the chosen row in the middle; rows have a fixed height so no measuring
  track.style.transform = `translateY(${MID - (sel * ROW + ROW / 2)}px)`;
  document.getElementById('stage').classList.remove('hidden');
}

window.addEventListener('message', (e) => {
  let m = e.data;
  if (typeof m === 'string') { try { m = JSON.parse(m); } catch (_) { return; } }
  if (!m || !m.action) return;
  if (m.action === 'shop:overlay') {
    if (!m.show) document.getElementById('stage').classList.add('hidden');
    return;
  }
  if (m.action !== 'shop:state') return;
  render(m.data || {});
});
