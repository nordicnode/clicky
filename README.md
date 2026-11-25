# Clicky's Cat Café

A sprite-based, semi-idle incremental game about running a one-table cat café.
A giant sleepy cat sits on the counter. Every pet earns **fish**. Fish buys cat
furniture, furniture attracts cats, and the cats keep earning while you're away.

Built in GameMaker (GML), 1920×1080 UI over 480×270 pixel-art room scenes.

## Play it (Linux)

Download the AppImage and run it:

```bash
chmod +x Clicky-x86_64.AppImage
./Clicky-x86_64.AppImage
```

The build is committed in this repo at `dist/Clicky-x86_64.AppImage`
(SHA-256 `b972355b351f988be43236790d68d1952dff10a2bd8cc34a7063886f64ca44b5`).

It has been verified to launch and render the café scene, HUD and shop correctly
at 1920×1080. It carries GameMaker's Linux runner plus `assets/game.unx` (the
compiled game), so no GameMaker installation is needed to play.

## What's in the game

- **One currency, 14 producers.** Tapping the cat and buying furniture rows
  (`BOX`, `BED`, `TOYS`, … `CAKE`) raise fish per second; `scr_econ.gml` is the
  source of truth for the cost/rate tables.
- **Prestige layers.** Reset a run into a permanent multiplier, spend it on
  charms, unlock rooms, cats, the counter, journals and festivals.
- **Hollow.** A hidden layer unlocked at the far end of progression.
- **Offline earnings.** Come back to a welcome-back card paying out the time you
  were away (capped at 8h, extended by upgrades).
- **Collection layers.** A 24-cat album, stickers, hats, staff stations.
- **Tap feel.** Combo multiplier, 10× crits, drifting sparkles that pay frenzy.

## Repository layout

| Path | What it is |
| --- | --- |
| `Clicky/` | The GameMaker project (`Clicky.yyp`) — objects, scripts, sprites, room, sounds, platform options |
| `art/` | Source art and sounds used to generate sprites and audio |
| `docs/` | `DEV_PLAN.md` (design and roadmap), `UI_ARCHITECTURE.md` (draw-layer ownership) |
| `tools/` | Headless verification and tuning harnesses (save/offline checks, layout audit, screenshots, economy tuning) |
| `dist/` | The built Linux AppImage |
| `GAMEPLAY_INVENTORY.md` | Factual snapshot of everything currently in the build |

The game's GML lives in `Clicky/objects/*/` and `Clicky/scripts/*/`. Project
metadata (`*.yy`, `*.yyp`) is edited through GameMaker's `resourcetool`, not by
hand — see `Clicky/AGENTS.md`.

## Rebuilding

The build was produced headlessly with GameMaker's official CLI on Linux:

```bash
npx @gamemaker/gm-cli@2.4.1 compile Clicky/Clicky.yyp --target linux --runtime vm
```

Two notes for Linux packaging with `gm-cli`:

1. Igor (GameMaker's builder) shells out to the system `zip` when it assembles a
   package; install `zip` (`sudo pacman -S zip` on Arch) or provide a shim on
   `PATH`.
2. `--toolchain-options '{"linux":{"packageType":"appimage"}}'` builds a real
   `.AppImage`, but GameMaker's AppImage step chroots into Valve's Steam Runtime
   at `/opt/steam-runtime`, which is not installed here. This AppImage was
   therefore assembled from the AppDir GameMaker stages with `linuxdeploy`:

```bash
linuxdeploy --appdir ~/GameMakerStudio2/vm/Clicky/AppDir \
  --desktop-file ~/GameMakerStudio2/vm/Clicky/AppDir/usr/share/applications/Clicky.desktop \
  --icon-file ~/GameMakerStudio2/vm/Clicky/AppDir/Clicky.png \
  --output appimage
```

The AppImage is built against this machine's glibc, so it is not guaranteed to
run on distributions much older than the one that built it.

## License

No license has been chosen yet, so all rights are reserved by the author.
