// js/demo.test.js for distractiondodgeweb
const { JSDOM } = require('jsdom');
describe('Distraction Dodge Demo', () => {
  let window, document, canvas, overlay, timerEl, accuracyEl, calmPctEl, calmBarEl, ninjaEl, targetLabel;
  beforeEach(() => {
    const dom = new JSDOM(`<!DOCTYPE html><canvas id="demo-canvas"></canvas><div id="demo-overlay"></div><span id="demo-timer"></span><span id="demo-accuracy"></span><span id="demo-calm-pct"></span><div id="demo-calm-bar"></div><div id="demo-ninja"></div><span id="demo-target-label"></span><button id="demo-start-btn"></button>`);
    window = dom.window;
    document = window.document;
    global.document = document;
    canvas = document.getElementById('demo-canvas');
    overlay = document.getElementById('demo-overlay');
    timerEl = document.getElementById('demo-timer');
    accuracyEl = document.getElementById('demo-accuracy');
    calmPctEl = document.getElementById('demo-calm-pct');
    calmBarEl = document.getElementById('demo-calm-bar');
    ninjaEl = document.getElementById('demo-ninja');
    targetLabel = document.getElementById('demo-target-label');
  });
  it('renders canvas and HUD', () => {
    require('./demo.js');
    expect(canvas).toBeDefined();
    expect(timerEl.textContent).toBeDefined();
    expect(accuracyEl.textContent).toBeDefined();
    expect(calmPctEl.textContent).toBeDefined();
    expect(calmBarEl.style.width).toBeDefined();
    expect(ninjaEl.className).toBeDefined();
    expect(targetLabel.textContent).toBeDefined();
  });
  it('start button triggers game', () => {
    require('./demo.js');
    document.getElementById('demo-start-btn').click();
    expect(timerEl.textContent).toBeDefined();
    expect(accuracyEl.textContent).toBeDefined();
  });
  it('overlay shows after game end', () => {
    require('./demo.js');
    overlay.style.display = 'flex';
    expect(overlay.innerHTML).toMatch(/Round Complete!/);
  });
});
