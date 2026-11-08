#!/usr/bin/env python3
"""Не даёт hypridle заблокировать экран, пока используется геймпад.

hypridle реагирует только на активность клавиатуры/мыши (wl_seat),
а события геймпада идут напрямую в приложение. Поэтому во время игры
с геймпадом таймер простоя продолжает идти и экран блокируется.

Скрипт читает evdev-устройства геймпадов и, пока есть недавняя
активность, держит systemd idle-ингибитор. hypridle его уважает
(general:ignore_systemd_inhibit = 0).
"""

import os
import selectors
import signal
import subprocess
import sys
import time

try:
    import evdev
    from evdev import ecodes
except ImportError:
    sys.exit(0)

# Сколько секунд тишины геймпада ждать перед снятием блокировки.
# Больше таймаута блокировки hypridle (900 c), чтобы таймер не сработал
# в паузах между нажатиями (катсцены и т.п.).
HOLD_SECONDS = 1000
RESCAN_SECONDS = 2.0

GAMEPAD_BUTTONS = {
    ecodes.BTN_GAMEPAD,
    ecodes.BTN_JOYSTICK,
    ecodes.BTN_SOUTH,
    ecodes.BTN_EAST,
    ecodes.BTN_NORTH,
    ecodes.BTN_WEST,
    ecodes.BTN_TRIGGER,
    ecodes.BTN_THUMB,
    ecodes.BTN_THUMBL,
    ecodes.BTN_THUMBR,
    ecodes.BTN_TOP,
    ecodes.BTN_BASE,
}

STICK_BUTTONS = {
    ecodes.BTN_TRIGGER,
    ecodes.BTN_THUMB,
    ecodes.BTN_THUMBL,
    ecodes.BTN_THUMBR,
    ecodes.BTN_TOP,
}


def is_gamepad(dev):
    try:
        caps = dev.capabilities(verbose=False)
    except Exception:
        return False

    keys = set(caps.get(ecodes.EV_KEY, ()))
    axes = set(caps.get(ecodes.EV_ABS, ()))

    if keys & GAMEPAD_BUTTONS:
        return True

    # Некоторые джойстики без BTN_GAMEPAD/BTN_JOYSTICK
    return ecodes.ABS_X in axes and ecodes.ABS_Y in axes and bool(keys & STICK_BUTTONS)


class IdleInhibitor:
    def __init__(self):
        self.proc = None

    def acquire(self):
        if self.proc is not None and self.proc.poll() is None:
            return
        self.release()
        try:
            self.proc = subprocess.Popen(
                [
                    "systemd-inhibit",
                    "--what=idle",
                    "--who=hypr-gamepad-idle",
                    "--why=Gamepad is in use",
                    "--mode=block",
                    "sleep",
                    "infinity",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except Exception:
            self.proc = None

    def release(self):
        if self.proc is None:
            return
        if self.proc.poll() is None:
            try:
                os.killpg(os.getpgid(self.proc.pid), signal.SIGTERM)
            except Exception:
                pass
            try:
                self.proc.wait(timeout=3)
            except Exception:
                try:
                    os.killpg(os.getpgid(self.proc.pid), signal.SIGKILL)
                except Exception:
                    pass
        self.proc = None


def main():
    sel = selectors.DefaultSelector()
    watched = {}
    ignored = set()
    inhibitor = IdleInhibitor()
    last_activity = 0.0
    running = True

    def stop(*_):
        nonlocal running
        running = False

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    def drop(path):
        dev = watched.pop(path, None)
        if dev is None:
            return
        try:
            sel.unregister(dev.fd)
        except Exception:
            pass
        try:
            dev.close()
        except Exception:
            pass

    def rescan():
        present = set()
        try:
            paths = evdev.list_devices()
        except Exception:
            paths = []
        for path in paths:
            present.add(path)
            if path in watched or path in ignored:
                continue
            try:
                dev = evdev.InputDevice(path)
            except Exception:
                continue
            if not is_gamepad(dev):
                dev.close()
                ignored.add(path)
                continue
            try:
                dev.set_blocking(False)
            except Exception:
                pass
            watched[path] = dev
            sel.register(dev.fd, selectors.EVENT_READ, dev)
        for path in list(watched):
            if path not in present:
                drop(path)
        ignored.intersection_update(present)

    try:
        rescan()
        while running:
            for key, _ in sel.select(timeout=RESCAN_SECONDS):
                dev = key.data
                try:
                    for _event in dev.read():
                        pass
                    last_activity = time.monotonic()
                except BlockingIOError:
                    pass
                except OSError:
                    drop(dev.path)

            rescan()

            now = time.monotonic()
            if last_activity and now - last_activity < HOLD_SECONDS:
                inhibitor.acquire()
            else:
                inhibitor.release()
    finally:
        inhibitor.release()
        for path in list(watched):
            drop(path)
        sel.close()


if __name__ == "__main__":
    main()
