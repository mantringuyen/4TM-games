# Block Puzzle — 4TM (Godot 4.x)

A casual mobile & web block puzzle game built in **Godot 4.3** for the **4TM Games** ecosystem (`games.4tm.io.vn`).

## 1. 2 × 2 Gameplay Architecture (Game Mode × Play Style)

### Two Game Modes (`GameStateManager.GameMode`)
- **Classic (`CLASSIC`)**:
  - Horizontal row clearing only (vertical columns are never cleared).
  - No special items / boosters (`SpecialItemsBar` is hidden in HUD).
  - Royal Gold & Sapphire classic board presentation.
- **Modern (`MODERN` / `MODERN_DRAG_AND_DROP`)**:
  - Horizontal row AND vertical column clearing (including simultaneous intersections).
  - Special items / boosters enabled (`💣 BOM 3×3`, `↻ XOAY`, `✨ ĐỔI`).
  - Luminous Crystal-Magenta & Neon Aqua board presentation with visible `SpecialItemsBar`.

### Two Play Styles (`GameStateManager.PlayStyle`)
- **Falling (`FALLING`)**:
  - Pieces spawn at the top of the 8×8 board and fall downward.
  - Shows **ONLY the NEXT piece preview** (`TIẾP THEO / NEXT`) above the board (no redundant Current-piece preview).
  - Downward vertical gravity compacts remaining blocks in each column after row clears.
  - Layout: `HUD Header` → `Next Piece Preview` → `8×8 Board` → `Touch Controls` → `Bottom AdSlot`.
- **Drag & Drop (`DRAG_AND_DROP`)**:
  - Displays a 3-piece tray with recessed pedestals below the 8×8 board.
  - When all 3 pieces are placed, a new set of 3 pieces is generated indefinitely until game over.
  - No automatic gravity after line clears.
  - Layout: `HUD Header` → `8×8 Board` → `3-Piece Tray` → `Bottom AdSlot`.

### Four Supported Combinations
1. **Classic + Falling**
2. **Classic + Drag & Drop**
3. **Modern + Falling**
4. **Modern + Drag & Drop**

## 2. Audio System (`scripts/autoload/audio_manager.gd`)
- **Looping Background Music**: Multi-voice 16-bit PCM marimba melody + warm Rhodes chord pad + bass groove (`AudioStreamWAV.LOOP_FORWARD`).
- **13 Distinct Sound Effects**: `button_press`, `piece_pickup`, `piece_movement`, `valid_placement`, `invalid_placement`, `rotation`, `row_clear`, `column_clear`, `multi_line_clear`, `combo`, `level_up`, `game_over`, `special_item`.
- **Voice Callouts**: Multi-formant vocal synthesis + celebratory chime and HUD banner for `NICE!`, `GREAT!`, `EXCELLENT!`, `COMBO!`, and `AMAZING!`.
- **Independent Audio Settings**: Separate `Music (ON/OFF)` and `Sound Effects (ON/OFF)` toggles persisted across the session.

## 3. Running Headless Tests
```bash
godot --headless --path games/block-puzzle scenes/test_runner.tscn
```
