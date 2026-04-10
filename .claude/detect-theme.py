#!/usr/bin/env python3
"""Detect terminal theme (light/dark) via OSC 11, macOS defaults, or env var."""

import os
import re
import subprocess
from typing import Optional


def detect_osc11() -> Optional[str]:
    """Query terminal background color via OSC 11.

    Uses /dev/tty directly so it works even when stdout is captured by
    shell command substitution (e.g. ``theme=$(python3 detect-theme.py)``).
    """
    try:
        tty_fd = os.open("/dev/tty", os.O_RDWR)
    except OSError:
        return None

    import select
    import termios
    import tty

    old = termios.tcgetattr(tty_fd)
    try:
        tty.setraw(tty_fd)
        os.write(tty_fd, b"\x1b]11;?\x1b\\")
        resp = b""
        while select.select([tty_fd], [], [], 0.5)[0]:
            resp += os.read(tty_fd, 256)
            if b"\x1b\\" in resp or b"\x07" in resp:
                break
    finally:
        termios.tcsetattr(tty_fd, termios.TCSADRAIN, old)
        os.close(tty_fd)

    m = re.search(rb"rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)", resp)
    if not m:
        return None

    vals = []
    for g in m.groups():
        v = int(g, 16)
        vals.append(v / 0xFF if len(g) <= 2 else v / 0xFFFF)

    lum = 0.299 * vals[0] + 0.587 * vals[1] + 0.114 * vals[2]
    return "light" if lum > 0.5 else "dark"


def detect_macos() -> Optional[str]:
    """Check macOS appearance via defaults command."""
    try:
        subprocess.run(
            ["defaults", "read", "-g", "AppleInterfaceStyle"],
            capture_output=True,
            check=True,
        )
        return "dark"
    except (FileNotFoundError, subprocess.CalledProcessError):
        # FileNotFoundError: not macOS. CalledProcessError: light mode (key absent).
        pass

    # Only return "light" if we're actually on macOS (defaults exists)
    if os.path.exists("/usr/bin/defaults"):
        return "light"
    return None


def detect_env() -> Optional[str]:
    """Read MACOS_SYSTEM_THEME env var."""
    val = os.environ.get("MACOS_SYSTEM_THEME", "")
    return val if val in ("light", "dark") else None


def main():
    theme = detect_osc11() or detect_macos() or detect_env()
    if theme:
        print(theme)


if __name__ == "__main__":
    main()
