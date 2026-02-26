# Distraction Dodge

An ADHD-friendly focus training game by [Foculoom](https://foculoom.com).

## Concept

A shape appears on screen labeled "TAP THE ⭕️". Tap only that shape — decoys try to bait you. Tap the wrong shape and you lose a life. Stay accurate to keep your ninja calm-meter high.

Built on the science of **inhibitory control** — a key executive function for ADHD brains.

## Gameplay

- 4 shape types: ⭕️ Circle, 🟦 Square, 🔺 Triangle, 💠 Diamond
- Each round spawns 1 target + 1–3 decoys (scales with difficulty)
- Correct tap → +1 score, ninja gets calmer
- Wrong tap → lose 1 life (❤️❤️❤️), ninja panics
- Target rotates after every correct tap
- Game ends when time runs out or all lives lost

## Ninja Calm Meter

| Emoji | State | Accuracy |
|-------|-------|---------|
| 🧘 | ZEN FOCUS | 80%+ |
| 😌 | CALM | 60–79% |
| 🙂 | STEADY | 40–59% |
| 😐 | DISTRACTED | 20–39% |
| 😤 | FRANTIC | <20% |

## Tech

- Swift 6, SwiftUI + SpriteKit
- iOS 17+ / iPadOS 17+
- 100% offline, no accounts, no ads

## Build

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
cd distractiondodge
xcodegen generate
open DistractionDodge.xcodeproj
```
