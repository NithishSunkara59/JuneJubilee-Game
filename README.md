# June Jubilee

June Jubilee is a touch-first iOS arcade game made for the June Solstice Game Jam. The player guides a small keeper of light through falling June celebrations, collecting as many as possible while keeping the solstice meter balanced between day and night.

## Theme Fit

The game treats June as a constellation of transitions and celebrations:

- Solstice tokens stretch the day and challenge the player to restore balance.
- Pride tokens reward streaks and celebrate authenticity.
- Juneteenth tokens recenter the balance meter as a symbol of restoration, liberation, and joy.
- Turing tokens open a timed binary cipher. The player must collect falling `0` and `1` tiles in the displayed order to crack the code.
- Soccer, sushi, and flip-flop tokens bring in June's playful global and specific celebrations.

## How to Play

Open `JuneJubilee.xcodeproj` in Xcode, select an iPhone simulator, and run.

- Drag anywhere on the screen to move the light keeper.
- Collect celebration tiles for points.
- Avoid dark shadow orbs, which break your streak and disrupt the balance.
- Keep the day/night meter near the center for better scoring.
- When a Turing cipher appears, collect the binary bits in order before the signal fades.
- Score as high as possible in 90 seconds.

## Technical Notes

The app is built with SwiftUI and SpriteKit. SwiftUI handles the HUD, start/end panels, cipher display, and app lifecycle. SpriteKit powers the arcade scene, physics contacts, animations, touch movement, and binary-code token spawning.
  
### Best Ode to Alan Turing

This submission meaningfully pursues the Alan Turing category. Turing tokens do more than award points: they start a short code-breaking challenge inspired by binary logic and early computing. A generated binary sequence appears in the HUD, `0` and `1` tiles begin falling into the playfield, and the player has to collect the correct bits in order. Completing the sequence gives a large bonus and releases extra light tokens, turning Turing's computing legacy into a playable mechanic.

## Submission Blurb

June Jubilee is a tiny festival in motion: part solstice balancing act, part celebration collector, part code-breaking sprint. I wanted the June themes to affect how the game plays, not just what it looks like. Solstice light pulls the meter toward day, Juneteenth restores harmony, Pride rewards confident streaks, and Alan Turing's signal opens a timed binary cipher where the player collects `0` and `1` tiles in the right order. The result is a fast, warm iOS arcade game about honoring many kinds of June light without letting any one of them drown out the rest.
