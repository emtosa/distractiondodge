/* =========================================
   Distraction Dodge — interactive web demo
   30-second focus training game
   ========================================= */
(function () {
  'use strict';

  // ── Constants ────────────────────────────────────────────────
  const GAME_DURATION    = 30;
  const RENDER_INTERVAL  = 1200;  // ms between shape refreshes
  const TARGET_INTERVAL  = 5000;  // ms between target-type changes
  const SHAPE_COUNT      = 7;
  const BASE_SIZE        = 34;
  const TARGET_SIZE      = 44;

  const SHAPES      = ['circle', 'square', 'triangle', 'star', 'diamond'];
  const SHAPE_EMOJI = { circle: '●', square: '■', triangle: '▲', star: '★', diamond: '◆' };
  const SHAPE_NAME  = { circle: 'circle', square: 'square', triangle: 'triangle', star: 'star', diamond: 'diamond' };

  const PALETTE = [
    '#6366f1', '#f97316', '#10b981', '#ef4444',
    '#f59e0b', '#06b6d4', '#8b5cf6', '#ec4899',
  ];

  // ── State ────────────────────────────────────────────────────
  let gameRunning  = false;
  let hits         = 0;
  let misses       = 0;
  let timeLeft     = GAME_DURATION;
  let targetType   = null;
  let placedShapes = [];
  let renderTick   = null;
  let targetTick   = null;
  let timerTick    = null;
  let rafId        = null;
  let wobbleT      = 0;

  // ── DOM refs ─────────────────────────────────────────────────
  const canvas      = document.getElementById('demo-canvas');
  const ctx         = canvas.getContext('2d');
  const overlay     = document.getElementById('demo-overlay');
  const timerEl     = document.getElementById('demo-timer');
  const accuracyEl  = document.getElementById('demo-accuracy');
  const calmPctEl   = document.getElementById('demo-calm-pct');
  const calmBarEl   = document.getElementById('demo-calm-bar');
  const ninjaEl     = document.getElementById('demo-ninja');
  const targetLabel = document.getElementById('demo-target-label');

  // ── CSS variable colours resolved at runtime ─────────────────
  const cs       = getComputedStyle(document.documentElement);
  const ACCENT   = cs.getPropertyValue('--accent').trim()    || '#4f46e5';
  const HIGHLIGHT = cs.getPropertyValue('--highlight').trim() || '#7c3aed';
  const STONE900 = cs.getPropertyValue('--stone-900').trim() || '#1c1917';
  const BG_CARD  = cs.getPropertyValue('--bg-card').trim()   || '#ffffff';

  // ── Helpers ──────────────────────────────────────────────────
  function getAccuracy() {
    const total = hits + misses;
    return total === 0 ? 0 : Math.round(hits / total * 100);
  }

  function rand(min, max)    { return min + Math.random() * (max - min); }
  function randInt(min, max) { return Math.floor(rand(min, max + 0.999)); }

  // ── Canvas drawing ───────────────────────────────────────────
  function applyStroke(isTarget) {
    if (!isTarget) return;
    ctx.strokeStyle = ACCENT;
    ctx.lineWidth   = 4.5;
    ctx.stroke();
  }

  function drawCircle(x, y, sz, fill, isTarget) {
    ctx.beginPath();
    ctx.arc(x, y, sz / 2, 0, Math.PI * 2);
    ctx.fillStyle = fill;
    ctx.fill();
    applyStroke(isTarget);
  }

  function drawSquare(x, y, sz, fill, isTarget) {
    const h = sz / 2;
    ctx.beginPath();
    if (ctx.roundRect) ctx.roundRect(x - h, y - h, sz, sz, 5);
    else               ctx.rect(x - h, y - h, sz, sz);
    ctx.fillStyle = fill;
    ctx.fill();
    applyStroke(isTarget);
  }

  function drawTriangle(x, y, sz, fill, isTarget) {
    const h = sz * 0.86;
    ctx.beginPath();
    ctx.moveTo(x,           y - h / 2);
    ctx.lineTo(x + sz / 2,  y + h / 2);
    ctx.lineTo(x - sz / 2,  y + h / 2);
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();
    applyStroke(isTarget);
  }

  function drawStar(x, y, sz, fill, isTarget) {
    const outerR = sz / 2;
    const innerR = outerR * 0.42;
    ctx.beginPath();
    for (let i = 0; i < 10; i++) {
      const r     = i % 2 === 0 ? outerR : innerR;
      const angle = (i * Math.PI / 5) - Math.PI / 2;
      const px    = x + r * Math.cos(angle);
      const py    = y + r * Math.sin(angle);
      i === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py);
    }
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();
    applyStroke(isTarget);
  }

  function drawDiamond(x, y, sz, fill, isTarget) {
    const h = sz / 2;
    ctx.beginPath();
    ctx.moveTo(x,     y - h);
    ctx.lineTo(x + h, y    );
    ctx.lineTo(x,     y + h);
    ctx.lineTo(x - h, y    );
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();
    applyStroke(isTarget);
  }

  function drawShape(s, wobble) {
    const wx = s.x + Math.sin(wobble * 2.5 + s.x * 0.07) * 1.8;
    const wy = s.y + Math.cos(wobble * 2.0 + s.y * 0.07) * 1.5;
    switch (s.type) {
      case 'circle':   drawCircle  (wx, wy, s.size, s.fill, s.isTarget); break;
      case 'square':   drawSquare  (wx, wy, s.size, s.fill, s.isTarget); break;
      case 'triangle': drawTriangle(wx, wy, s.size, s.fill, s.isTarget); break;
      case 'star':     drawStar    (wx, wy, s.size, s.fill, s.isTarget); break;
      case 'diamond':  drawDiamond (wx, wy, s.size, s.fill, s.isTarget); break;
    }
    // Extra glow ring for target
    if (s.isTarget) {
      ctx.beginPath();
      ctx.arc(wx, wy, s.size / 2 + 8, 0, Math.PI * 2);
      ctx.strokeStyle = HIGHLIGHT;
      ctx.lineWidth   = 2;
      ctx.globalAlpha = 0.35 + 0.2 * Math.sin(wobble * 4);
      ctx.stroke();
      ctx.globalAlpha = 1;
    }
  }

  // ── Hit testing ──────────────────────────────────────────────
  function hitTest(s, cx, cy) {
    const dx = cx - s.x;
    const dy = cy - s.y;
    const r  = s.size / 2 + 8;
    switch (s.type) {
      case 'diamond': return (Math.abs(dx) + Math.abs(dy)) <= r * 1.2;
      case 'circle':
      case 'star':    return Math.sqrt(dx * dx + dy * dy) <= r;
      default:        return Math.abs(dx) <= r && Math.abs(dy) <= r;
    }
  }

  // ── Place shapes ─────────────────────────────────────────────
  function placeShapes() {
    const W      = canvas.width;
    const H      = canvas.height;
    const margin = TARGET_SIZE + 8;

    // Build type list: exactly one target, rest non-target
    const nonTargets = SHAPES.filter(t => t !== targetType);
    const types = [targetType];
    for (let i = 1; i < SHAPE_COUNT; i++) {
      types.push(nonTargets[randInt(0, nonTargets.length - 1)]);
    }
    // Shuffle
    for (let i = types.length - 1; i > 0; i--) {
      const j = randInt(0, i);
      [types[i], types[j]] = [types[j], types[i]];
    }

    const placed = [];
    let targetAssigned = false;

    for (let i = 0; i < SHAPE_COUNT; i++) {
      const type     = types[i];
      const isTarget = type === targetType && !targetAssigned;
      if (isTarget) targetAssigned = true;
      const size     = isTarget ? TARGET_SIZE : BASE_SIZE;
      const colorIdx = isTarget ? 0 : (1 + ((i - 1) % (PALETTE.length - 1)));

      let x, y, tries = 0;
      do {
        x = rand(margin, W - margin);
        y = rand(margin, H - margin);
        tries++;
      } while (tries < 40 && placed.some(p => {
        const minD = (size + p.size) / 2 + 12;
        return Math.hypot(x - p.x, y - p.y) < minD;
      }));

      placed.push({ type, x, y, size, isTarget, fill: PALETTE[colorIdx] });
    }
    return placed;
  }

  // ── Render loop ──────────────────────────────────────────────
  function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (const s of placedShapes) drawShape(s, wobbleT);
    wobbleT += 0.045;
    if (gameRunning) rafId = requestAnimationFrame(render);
  }

  // ── UI update ────────────────────────────────────────────────
  function updateUI() {
    const mins = Math.floor(timeLeft / 60);
    const secs = timeLeft % 60;
    timerEl.textContent    = `${mins}:${secs.toString().padStart(2, '0')}`;
    const total            = hits + misses;
    const acc              = getAccuracy();
    accuracyEl.textContent = total > 0 ? `${acc}%` : '—';
    calmPctEl.textContent  = `${acc}%`;
    calmBarEl.style.width  = `${acc}%`;

    if (acc >= 70)       ninjaEl.className = 'demo-ninja calm';
    else if (acc >= 40)  ninjaEl.className = 'demo-ninja settling';
    else                 ninjaEl.className = 'demo-ninja frantic';
  }

  function setTargetLabel() {
    targetLabel.textContent = `Tap the ${SHAPE_EMOJI[targetType]} (${SHAPE_NAME[targetType]})`;
  }

  // ── Game flow ────────────────────────────────────────────────
  function startGame() {
    hits = 0; misses = 0; timeLeft = GAME_DURATION; wobbleT = 0;
    gameRunning = true;

    overlay.style.display = 'none';
    targetLabel.textContent = '';

    targetType   = SHAPES[randInt(0, SHAPES.length - 1)];
    setTargetLabel();
    placedShapes = placeShapes();
    updateUI();
    rafId = requestAnimationFrame(render);

    renderTick = setInterval(() => {
      placedShapes = placeShapes();
    }, RENDER_INTERVAL);

    targetTick = setInterval(() => {
      targetType = SHAPES[randInt(0, SHAPES.length - 1)];
      setTargetLabel();
    }, TARGET_INTERVAL);

    timerTick = setInterval(() => {
      timeLeft--;
      updateUI();
      if (timeLeft <= 0) endGame();
    }, 1000);
  }

  function endGame() {
    gameRunning = false;
    clearInterval(renderTick);
    clearInterval(targetTick);
    clearInterval(timerTick);
    cancelAnimationFrame(rafId);

    targetLabel.textContent = '';
    const acc = getAccuracy();

    // Dim canvas
    ctx.fillStyle = 'rgba(250,250,249,0.6)';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    overlay.style.display = 'flex';
    overlay.innerHTML = `
      <div class="demo-results">
        <p class="results-title">Round Complete! 🥷</p>
        <p class="results-stat">Accuracy: <strong>${acc}%</strong></p>
        <p class="results-stat">Calm Meter: <strong>${acc}%</strong></p>
        <button id="demo-play-again" class="btn btn-highlight">▶ Play Again</button>
      </div>`;
    document.getElementById('demo-play-again').addEventListener('click', startGame);
  }

  // ── Input handling ───────────────────────────────────────────
  function handleInput(clientX, clientY) {
    if (!gameRunning) return;
    const rect  = canvas.getBoundingClientRect();
    const scaleX = canvas.width  / rect.width;
    const scaleY = canvas.height / rect.height;
    const cx     = (clientX - rect.left) * scaleX;
    const cy     = (clientY - rect.top)  * scaleY;

    let hitTarget = false;
    let hitAny    = false;
    for (const s of placedShapes) {
      if (hitTest(s, cx, cy)) {
        hitAny    = true;
        hitTarget = s.isTarget;
        break;
      }
    }
    if (!hitAny) return;

    if (hitTarget) hits++; else misses++;
    updateUI();
    placedShapes = placeShapes();  // refresh on any hit
  }

  canvas.addEventListener('click', e => handleInput(e.clientX, e.clientY));
  canvas.addEventListener('touchstart', e => {
    e.preventDefault();
    const t = e.changedTouches[0];
    handleInput(t.clientX, t.clientY);
  }, { passive: false });

  // ── Init ─────────────────────────────────────────────────────
  document.getElementById('demo-start-btn').addEventListener('click', startGame);

}());
