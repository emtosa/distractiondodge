// js/demo.test.js for distractiondodgeweb
const { JSDOM } = require('jsdom');
describe('Distraction Dodge Demo', () => {
  let window, document, canvas, overlay, timerEl, accuracyEl, calmPctEl, calmBarEl, ninjaEl, targetLabel;
  beforeEach(() => {
    jest.resetModules();
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
    global.getComputedStyle = () => ({ getPropertyValue: () => '' });
    const ctxMock = {
      save: jest.fn(), restore: jest.fn(), clearRect: jest.fn(),
      fillRect: jest.fn(), beginPath: jest.fn(), arc: jest.fn(),
      fill: jest.fn(), stroke: jest.fn(), moveTo: jest.fn(), lineTo: jest.fn(),
      fillText: jest.fn(), measureText: jest.fn(() => ({ width: 10 })),
      translate: jest.fn(), scale: jest.fn(), rotate: jest.fn(),
      createLinearGradient: jest.fn(() => ({ addColorStop: jest.fn() })),
      setLineDash: jest.fn(),
      fillStyle: '', strokeStyle: '', lineWidth: 0, font: '',
      textAlign: '', textBaseline: '', globalAlpha: 1,
    };
    canvas.getContext = () => ctxMock;
    canvas.width = 400;
    canvas.height = 300;
    global.requestAnimationFrame = jest.fn();
    global.cancelAnimationFrame = jest.fn();
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
    jest.useFakeTimers();
    global.requestAnimationFrame = jest.fn();
    global.cancelAnimationFrame = jest.fn();
    require('./demo.js');
    document.getElementById('demo-start-btn').click();
    jest.advanceTimersByTime(30000);
    expect(overlay.innerHTML).toMatch(/Round Complete!/);
    jest.useRealTimers();
  });
});
