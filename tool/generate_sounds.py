#!/usr/bin/env python3
"""Generate the original Zrobleno UI sound palette using only stdlib."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


RATE = 44_100
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "sounds"


def buffer(seconds: float) -> list[float]:
    return [0.0] * int(RATE * seconds)


def envelope(t: float, duration: float, attack: float, release: float) -> float:
    rise = min(1.0, t / max(attack, 1e-6))
    fall = min(1.0, max(0.0, duration - t) / max(release, 1e-6))
    return rise * fall


def add_tone(
    out: list[float],
    start: float,
    duration: float,
    frequency: float,
    gain: float,
    *,
    wave_type: str = "sine",
    attack: float = 0.008,
    release: float = 0.12,
    vibrato: float = 0.0,
) -> None:
    first = int(start * RATE)
    count = int(duration * RATE)
    phase = 0.0
    for i in range(count):
        index = first + i
        if index >= len(out):
            break
        t = i / RATE
        freq = frequency * (1.0 + vibrato * math.sin(2 * math.pi * 5.2 * t))
        phase += 2 * math.pi * freq / RATE
        if wave_type == "triangle":
            value = 2 / math.pi * math.asin(math.sin(phase))
        elif wave_type == "square":
            value = 1.0 if math.sin(phase) >= 0 else -1.0
        else:
            value = math.sin(phase)
        env = envelope(t, duration, attack, release) * math.exp(-1.6 * t / duration)
        out[index] += value * gain * env


def add_bell(
    out: list[float], start: float, duration: float, frequency: float, gain: float
) -> None:
    partials = ((1.0, 1.0), (2.01, 0.34), (3.98, 0.12), (6.02, 0.05))
    for ratio, level in partials:
        add_tone(
            out,
            start,
            duration,
            frequency * ratio,
            gain * level,
            attack=0.003,
            release=min(0.22, duration * 0.7),
        )


def add_chirp(
    out: list[float],
    start: float,
    duration: float,
    from_hz: float,
    to_hz: float,
    gain: float,
) -> None:
    first = int(start * RATE)
    count = int(duration * RATE)
    phase = 0.0
    for i in range(count):
        index = first + i
        if index >= len(out):
            break
        t = i / RATE
        progress = t / duration
        frequency = from_hz * ((to_hz / from_hz) ** progress)
        phase += 2 * math.pi * frequency / RATE
        flutter = 0.76 + 0.24 * math.sin(2 * math.pi * 27 * t) ** 2
        env = envelope(t, duration, 0.006, 0.035)
        out[index] += math.sin(phase) * gain * env * flutter


def add_noise_click(out: list[float], start: float, duration: float, gain: float) -> None:
    rng = random.Random(7614)
    first = int(start * RATE)
    count = int(duration * RATE)
    previous = 0.0
    for i in range(count):
        index = first + i
        if index >= len(out):
            break
        t = i / RATE
        raw = rng.uniform(-1.0, 1.0)
        filtered = raw - previous * 0.82
        previous = raw
        out[index] += filtered * gain * math.exp(-48 * t)


def apply_echo(out: list[float], delays: tuple[tuple[float, float], ...]) -> None:
    dry = out[:]
    for delay, gain in delays:
        offset = int(delay * RATE)
        for index in range(offset, len(out)):
            out[index] += dry[index - offset] * gain


def save(name: str, out: list[float]) -> None:
    peak = max(max(abs(value) for value in out), 1e-6)
    scale = min(0.88 / peak, 1.0)
    frames = bytearray()
    for value in out:
        shaped = math.tanh(value * scale * 1.18) / math.tanh(1.18)
        frames.extend(struct.pack("<h", int(max(-1.0, min(1.0, shaped)) * 32767)))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / name), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(frames)


def make_tap() -> list[float]:
    out = buffer(0.16)
    add_noise_click(out, 0.004, 0.07, 0.20)
    add_tone(out, 0.0, 0.10, 880.0, 0.18, wave_type="triangle", release=0.07)
    return out


def make_confirm() -> list[float]:
    out = buffer(0.42)
    add_bell(out, 0.01, 0.24, 587.33, 0.27)
    add_bell(out, 0.105, 0.28, 880.00, 0.29)
    apply_echo(out, ((0.075, 0.12),))
    return out


def make_task_complete() -> list[float]:
    out = buffer(0.82)
    for start, note, gain in (
        (0.00, 523.25, 0.23),
        (0.10, 659.25, 0.24),
        (0.20, 783.99, 0.26),
        (0.31, 1046.50, 0.32),
    ):
        add_bell(out, start, 0.42, note, gain)
    add_chirp(out, 0.47, 0.16, 1300, 2050, 0.10)
    apply_echo(out, ((0.105, 0.10), (0.19, 0.055)))
    return out


def make_reward() -> list[float]:
    out = buffer(1.18)
    add_tone(out, 0.0, 0.35, 261.63, 0.16, wave_type="triangle", release=0.24)
    for start, note in ((0.08, 523.25), (0.20, 659.25), (0.32, 783.99), (0.46, 1174.66)):
        add_bell(out, start, 0.55, note, 0.25)
    add_chirp(out, 0.62, 0.24, 1480, 2520, 0.11)
    apply_echo(out, ((0.13, 0.13), (0.26, 0.07)))
    return out


def make_morning() -> list[float]:
    out = buffer(1.55)
    for start, note, gain in (
        (0.00, 392.00, 0.16),
        (0.18, 493.88, 0.19),
        (0.37, 587.33, 0.23),
        (0.58, 783.99, 0.25),
    ):
        add_bell(out, start, 0.68, note, gain)
    add_chirp(out, 0.77, 0.18, 1420, 2200, 0.11)
    add_chirp(out, 0.98, 0.15, 1770, 1320, 0.08)
    apply_echo(out, ((0.16, 0.10), (0.31, 0.055)))
    return out


def make_notification() -> list[float]:
    out = buffer(1.25)
    for start, note, gain in (
        (0.00, 587.33, 0.24),
        (0.16, 880.00, 0.27),
        (0.34, 739.99, 0.23),
        (0.52, 1174.66, 0.30),
    ):
        add_bell(out, start, 0.58, note, gain)
    add_chirp(out, 0.72, 0.13, 1520, 2150, 0.075)
    apply_echo(out, ((0.14, 0.12), (0.28, 0.06)))
    return out


def make_soft_error() -> list[float]:
    out = buffer(0.38)
    add_tone(out, 0.00, 0.24, 392.00, 0.18, wave_type="triangle", release=0.15)
    add_tone(out, 0.095, 0.25, 311.13, 0.17, wave_type="triangle", release=0.16)
    return out


def main() -> None:
    sounds = {
        "ui_tap.wav": make_tap(),
        "action_confirm.wav": make_confirm(),
        "task_complete.wav": make_task_complete(),
        "reward_unlock.wav": make_reward(),
        "morning_sun.wav": make_morning(),
        "zrobleno_notification.wav": make_notification(),
        "soft_error.wav": make_soft_error(),
    }
    for name, samples in sounds.items():
        save(name, samples)
        print(OUTPUT / name)


if __name__ == "__main__":
    main()
