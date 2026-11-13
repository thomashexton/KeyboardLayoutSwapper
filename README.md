# KeyboardLayoutSwapper

WoW Forever addon that remaps your keybinds onto the **same physical keys** when you switch keyboard layouts (QWERTY, Colemak-DH, Colemak, Dvorak).

## Forever Interface

- **Interface:** `16001` (World of Warcraft Forever)
- Install under `_forever_/Interface/AddOns/KeyboardLayoutSwapper`

## Install (WowUpHub / manual)

1. Clone or download this repo so the folder name is exactly `KeyboardLayoutSwapper`.
2. Place it in:
   - macOS: `/Applications/World of Warcraft/_forever_/Interface/AddOns/KeyboardLayoutSwapper`
3. Restart the Forever client (or `/reload`) and enable the addon.

WowUpHub: repo name matches the addon folder name (`KeyboardLayoutSwapper`).

## Usage

- Minimap button: click to cycle layouts in your configured list
- Slash commands: `/kls`, `/keyboardlayoutswapper`
  - `/kls` — toggle / cycle
  - `/kls qwerty` (or `colemak-dh`, `colemak-classic`, `dvorak`) — switch to a layout
  - `/kls use qwerty dvorak` — set which layouts the click cycle uses
  - `/kls stamp qwerty` — mark the current layout without moving keys
  - `/kls auto colemak-dh` — prefer a layout on this computer at login (`/kls auto off` to disable)

## Author

Thomas Hexton
