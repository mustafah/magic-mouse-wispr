import Foundation
import MultitouchSupport

@_silgen_name("MTDeviceCreateList")
func MTDeviceCreateList() -> Unmanaged<CFMutableArray>?

private let wantedFingers = 3
private let maxTimeDelta: TimeInterval = 0.3
private let maxDistanceDelta: Float = 0.05
private let debounce: TimeInterval = 0.12
private let doubleTapWindow: TimeInterval = 0.32

private final class TapState {
  var touching = false
  var startTime: TimeInterval = 0
  var valid = true
  var firstPos: (Float, Float)?
  var lastPos: (Float, Float)?
}

private let state = TapState()
private let lock = NSLock()
private var lastTapTime: TimeInterval = 0
private var awaitingDouble = false
private var doubleGeneration = 0
private var isHandsFree = false

private func startWispr() {
  let p = Process()
  p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
  p.arguments = ["wispr-flow://start-hands-free"]
  try? p.run()
}

private func stopWispr() {
  let p = Process()
  p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
  p.arguments = ["wispr-flow://stop-hands-free"]
  try? p.run()
}

private func log(_ message: String) {
  print(message)
  fflush(stdout)
}

private func onValidTap() {
  let now = ProcessInfo.processInfo.systemUptime

  if awaitingDouble, now - lastTapTime <= doubleTapWindow {
    awaitingDouble = false
    doubleGeneration += 1
    triggerWispr()
    return
  }

  awaitingDouble = true
  lastTapTime = now
  let gen = doubleGeneration
  DispatchQueue.main.asyncAfter(deadline: .now() + doubleTapWindow) {
    lock.lock()
    defer { lock.unlock() }
    if awaitingDouble, gen == doubleGeneration {
      awaitingDouble = false
    }
  }
}

private func triggerWispr() {
  if isHandsFree {
    stopWispr()
  } else {
    startWispr()
  }
  isHandsFree.toggle()
  log("wispr-tap: toggled -> \(isHandsFree ? "hands-free ON" : "OFF")")
}

private let touchCallback: MTFrameCallbackFunction = { _, touches, numTouches, _, _ in
  lock.lock()
  defer { lock.unlock() }

  let now = ProcessInfo.processInfo.systemUptime
  let touchBuf = UnsafeBufferPointer(start: touches, count: Int(numTouches))

  if numTouches == 0 {
    guard state.touching else { return }
    state.touching = false
    defer {
      state.valid = true
      state.firstPos = nil
      state.lastPos = nil
    }
    let elapsed = now - state.startTime
    guard state.valid,
          elapsed <= maxTimeDelta,
          elapsed > 0.04,
          let f = state.firstPos,
          let l = state.lastPos else { return }
    let delta = abs(f.0 - l.0) + abs(f.1 - l.1)
    guard delta < maxDistanceDelta else { return }
    guard now - lastTapTime > debounce else { return }
    onValidTap()
  } else {
    if !state.touching {
      state.touching = true
      state.startTime = now
      state.valid = true
      if touchBuf.count == wantedFingers {
        var sum: (Float, Float) = (0, 0)
        for t in touchBuf {
          sum.0 += t.normalizedVector.position.x
          sum.1 += t.normalizedVector.position.y
        }
        state.firstPos = sum
        state.lastPos = sum
      }
      return
    }

    if touchBuf.count != wantedFingers {
      state.valid = false
      return
    }
    var sum: (Float, Float) = (0, 0)
    for t in touchBuf {
      sum.0 += t.normalizedVector.position.x
      sum.1 += t.normalizedVector.position.y
    }
    state.lastPos = sum
  }
}

let devices = MTDeviceCreateList()?.takeUnretainedValue() as? [MTDevice] ?? []
for device in devices where device.isAlive {
  device.register(contactFrameCallback: touchCallback)
  device.start(runMode: 0)
}

log("wispr-tap: listening on \(devices.count) multitouch device(s)")
log("wispr-tap: DOUBLE 3-finger tap toggles Wispr hands-free (single tap = normal middle click)")

CFRunLoopRun()