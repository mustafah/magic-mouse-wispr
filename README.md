# Magic Mouse Wispr

A tiny macOS helper that turns a **double three-finger tap** on your Magic Mouse (or trackpad) into a gesture that toggles [Wispr Flow](https://wisprflow.ai)'s free, hands-free dictation mode.

Built because Wispr Flow's own *middle-click* shortcut never fired: it listens on raw HID, while tools like [MiddleClick](https://github.com/artginzburg/MiddleClick) synthesize a *software* middle-click that Wispr's driver-level listener can't see. Instead of injecting clicks, `wispr-tap` reads the actual multitouch surface (the same private API MiddleClick uses) and tells Wispr directly through its URL scheme.

## Behavior

| Gesture | Result |
| --- | --- |
| Single 3-finger tap | Nothing (MiddleClick still handles this as a normal middle-click: close tab, paste, autoscroll) |
| Double 3-finger tap (< 0.32s apart) | Toggles Wispr Flow hands-free dictation on/off |

## Requirements

- macOS 11+ (Apple Silicon or Intel)
- [Wispr Flow](https://wisprflow.ai) installed, signed in
- Xcode Command Line Tools (`xcode-select --install`) — only needed to build
- Optional: [MiddleClick](https://github.com/artginzburg/MiddleClick) (`brew install --cask middleclick`) for the *normal* single-tap middle-click role

No Accessibility or Input Monitoring permission is needed — `wispr-tap` only reads touches and runs `open wispr-flow://...`.

## Install

```sh
git clone https://github.com/mustafah/magic-mouse-wispr.git
cd magic-mouse-wispr
chmod +x install.sh
./install.sh
```

That builds the helper, copies it next to the repo, and registers a `com.wispr-tap` LaunchAgent so it starts at login and stays alive.

## Use

1. Place two/three fingers on the Magic Mouse surface.
2. **Tap twice quickly** (double-tap).
3. Wispr Flow's free mode appears (or disappears).

Check the log while testing:

```sh
tail -f ~/Library/Logs/wispr-tap.log
```

You should see:

```
wispr-tap: toggled -> hands-free ON
wispr-tap: toggled -> OFF
```

## Tuning

The parameters live at the top of `Sources/wispr-tap/main.swift`:

| Constant | Default | Meaning |
| --- | --- | --- |
| `wantedFingers` | `3` | Number of fingers for the gesture |
| `maxTimeDelta` | `0.3` | Max seconds one tap can last |
| `maxDistanceDelta` | `0.05` | Max normalized movement during a tap |
| `doubleTapWindow` | `0.32` | Max gap between the two taps of a double-tap |
| `debounce` | `0.12` | Min gap used to ignore re-firing of a single tap |

Edit, then re-run `./install.sh`.

## Uninstall

```sh
./uninstall.sh
```

## How it works

- Watches `MTDevice` contact frames via the private `MultitouchSupport` framework (the same mechanism as MiddleClick).
- Detects a tap: surface contact ≤ `maxTimeDelta` long, with ≤ `maxDistanceDelta` of movement, using exactly `wantedFingers`.
- Requires two such taps within `doubleTapWindow` (so single taps stay normal middle-clicks).
- Toggles Wispr by calling `open "wispr-flow://start-hands-free"` / `stop-hands-free`, keeping a local on/off flag to decide which to send.

Known limitation: the on/off flag is in-memory. If you start/stop hands-free some other way, the next double-tap may fire the "wrong" deeplink; a second double-tap re-syncs it.

## Notes

- It registers on **all** multitouch devices it finds. On a Mac with a built-in trackpad, a two-finger... i.e. any 3-finger tap on the trackpad also triggers it.
- The double-tap also produces two ordinary middle-clicks (via MiddleClick) — harmless in most apps, and optional.