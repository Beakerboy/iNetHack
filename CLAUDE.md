# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

iNetHack: the NetHack roguelike ported to iOS. Objective-C (manual retain/release,
`CLANG_ENABLE_OBJC_ARC: NO`), targeting iOS 12+. The NetHack game engine itself is C
(the upstream NetHack C sources), wrapped by an Objective-C "window port" that renders
to UIKit and feeds keyboard/touch input back into the C engine's blocking I/O calls.

## Build

There is no checked-in `.xcodeproj` — it's generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```
brew install xcodegen   # macOS only
xcodegen generate
```

Building requires macOS + Xcode (`xcodebuild`) and is not possible on this Linux dev
box — there is no local build/test/lint command to run here. Treat changes as
source-review-only unless working from macOS. The authoritative build steps live in
`.github/workflows/ios-compile-test.yml`; before trusting a change, mentally (or
literally, on macOS) replay that workflow rather than assuming `xcodegen generate`
alone is sufficient — see the "nethack36 submodule" section below for why extra prep
steps are required first.

Key `xcodebuild` invocation from CI:
```
xcodebuild build -project "iNetHack2.xcodeproj" -scheme "iNetHack2" \
  -configuration Release -sdk iphoneos -destination "generic/platform=iOS" \
  ONLY_ACTIVE_ARCH=NO ARCHS="arm64" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

## Tests

`NetHackSharedUITests` (target in `project.yml`, sources in
`Tests/NetHackSharedUITests/`) is an XCTest bundle that tests `NetHackSharedUI`
in isolation, without a host app — it runs as a plain "library" test bundle in the
iOS Simulator, so it only covers code that doesn't touch UIKit rendering or the C
engine. On macOS:

```
xcodegen generate
xcodebuild test -scheme NetHackSharedUI -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Good TDD candidates are the Foundation/CoreGraphics-only classes in `Classes/` that
don't import UIKit or engine headers — e.g. `DMath`, `NSString+NetHack`,
`NSString+Regexp`, `TilePosition`, `PlayerState`, `Shortcut`. `DMathTests.m` is the
first test and a template for this pattern. Classes that touch UIKit (view
controllers, `Window`, tile rendering) or the C engine bridge
(`nethack/win/iphone/*`, `winiphone.c`) are not practical to unit test given the
manual retain/release + global-pointer-into-C-engine design; cover that behavior with
manual testing or XCUITest instead, not TDD.

This test target has not been run/verified — this dev box has no macOS/Xcode, so
`xcodegen generate` and `xcodebuild` can't execute here. Verify on macOS before
relying on it.

## Architecture: three engine generations, one shared UI

The repo carries the NetHack C engine in **three parallel copies** at the top level,
plus one shared Objective-C UI layer. Know which directory you're in before editing:

- **`Classes/`** — `NetHackSharedUI.framework`. Version-agnostic Objective-C UI:
  `AbstractMainViewController`, `AbstractNethackMenuViewController`, `Window`,
  `MainView`, tile-set/glyph rendering, menus, direction/extended-command input,
  the `NethackEventQueue`. This is where UI/UX changes usually belong. It knows
  nothing about which NetHack version is running underneath.
- **`nethack36/`** — a **git submodule** pointing at the pristine upstream
  `NetHack/NetHack` repo (`NetHack-3.6` branch). It is *not checked out* in a plain
  clone (`git submodule status` shows a `-` prefix) and contains no iOS port code of
  its own — it's just the vanilla 3.6 game engine C sources.
- **`nethack/`** — the customized 3.6-era iOS port: patched engine sources
  (32/64-bit compatibility fixes) plus `nethack/win/iphone/`, which is the *actual*
  concrete iOS window port for 3.6 (`MainViewController`, `NethackMenuViewController`,
  `RoleSelectionController`, `TileSet`, `AsciiTileSet`, `winiphone.c`, and
  `NH36EngineRunner` — the Obj-C entry point that launches the engine and hands it
  a UI context). **This is where 3.6 engine/port changes go, not `nethack36/`.**
- **`nethack34/`** — the older, largely self-contained NetHack 3.4.3 iOS port
  (own `dat/`, `win/iphone/` with just `winiphone.h/.m`). Its XcodeGen target
  (`NetHackEngine34`) is currently **commented out** in `project.yml`; the app
  currently ships only the 3.6 engine. Treat 3.4 code as legacy/reference unless
  asked to revive it.

### Why the submodule dance

`nethack36/include`, `nethack36/src`, and `nethack36/win/iphone` are referenced as
build sources in `project.yml` (target `NetHackEngine36`), but that directory is a
bare upstream checkout with no iOS port. The CI workflow
(`.github/workflows/ios-compile-test.yml`) populates it before building:
1. Runs `sys/unix/setup.sh` + `make makedefs`/data-file targets inside `nethack36`
   (using macOS hints) to generate engine data files.
2. Copies `nethack/include/*`, `nethack/src/*`, and `nethack/win/iphone` **on top of**
   `nethack36`, then compiles `share/tilemap.c` from that merged tree into a
   `tilemap_generator` binary and runs it to produce generated tile-mapping sources.
3. Only then runs `xcodegen generate` and `xcodebuild`.

So `nethack36` is a build-time overlay target, not a source-of-truth directory —
**edit engine/port code in `nethack/`**, and remember that a from-scratch build needs
those CI prep steps (submodule init + copy + tilemap generation), not just
`xcodegen generate`.

### Runtime wiring between C engine and Obj-C UI

- `winiphone.c`/`.m` implements NetHack's C `window procs` interface (the
  `winprocs`/`iphoneInitWindows`, `iphonePutStr`, etc., surfaced in Obj-C via
  `NHWindowPortDelegate`) and holds a **global pointer to the active
  `AbstractMainViewController`** (`iphone_set_ui_context`), since the C engine has no
  concept of object instances.
- `NH36EngineRunner` (`nethack/win/iphone/NH36EngineRunner.h/.m`) is the bridge: it
  instantiates the concrete `MainViewController` (a thin `AbstractMainViewController`
  subclass, `nethack/win/iphone/MainViewController.h/.m`), calls
  `iphone_set_ui_context(vc)` to wire it into the C side, then calls
  `launchNetHack` which spins up `nethackThread` and runs the blocking game loop
  (`mainNethackLoop:` / `runNativeEngineLoop`) off the main thread.
- Cross-thread coordination between the game thread and UI thread goes through
  `NSCondition`s (`textInputCondition`, `uiCondition`) and `NethackEventQueue`
  (blocking queue of `NethackEvent`s — keypresses, etc. — consumed by the engine
  thread, produced by UI callbacks on the main thread).
- `MainMenuApp/iNethackAppDelegate.m` is the app entry point: it imports
  `AbstractMainViewController`/`MainView` from `NetHackSharedUI` and
  `NH36EngineRunner` from `NetHackEngine36`, and calls
  `[NH36EngineRunner launchGameAndReturnViewController]` (indirectly, or via
  `AbstractMainViewController instance`) to start a game.

### Framework/module boundaries (see `project.yml`)

- `NetHackSharedUI.framework` — `Classes/`, public headers, no engine dependency.
- `NetHackEngine36.framework` — `nethack36/{include,src,win/iphone,sys/share}`
  (post CI-overlay), depends on `NetHackSharedUI.framework`.
- `iNetHack2` (app target) — `MainMenuApp/` + `Resources/`, links both frameworks.
  A post-build script copies `nethack34/dat/*` and `nethack36/dat/*` game data flat
  into the built app's root (`nethack34/`, `nethack36/` subfolders), since the C
  engine expects to find its data files there at runtime.
- Tilesets live under `Resources/Tilesets/nethack34` and
  `Resources/Tilesets/nethack36`, added as folder references (not group), and are
  excluded from the generic `Resources` glob to avoid double-inclusion.

### Naming convention

Files/classes prefixed `Abstract*` (`AbstractMainViewController`,
`AbstractNethackMenuViewController`, `AbstractTileSet`, `AbstractAsciiTileSet`) live in
`NetHackSharedUI` and are meant to be subclassed per-engine-version
(`nethack/win/iphone/MainViewController` etc. for 3.6). When adding version-specific
behavior, prefer overriding in the concrete subclass rather than adding
version-conditional branches to the `Abstract*` base.
