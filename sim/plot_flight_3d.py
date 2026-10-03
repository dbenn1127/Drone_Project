"""
plot_flight_3d.py - Replay a logged flight as an animated 3D plot.

Reads a flight log written by pattern_flight.py (or first_flight.py) and
draws the drone's path in 3D, colored by flight phase, with a moving marker
that replays the flight. The view slowly rotates so you can see the shape.

HOW TO RUN (in Command Prompt, from your Drone folder)
    python plot_flight_3d.py                          replays pattern_log.csv
    python plot_flight_3d.py altitude_log.csv         replays a different log
    python plot_flight_3d.py pattern_log.csv --save   also saves flight_3d.gif

    In the window, click and drag to rotate the view yourself.
    Close the window to exit.

NEEDS
    matplotlib (pip install matplotlib). Saving a GIF also uses pillow,
    which comes with matplotlib.
"""

import csv
import math
import sys

import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter


# ---------------------------------------------------------------------------
# SETTINGS
# ---------------------------------------------------------------------------
# Which log to read: the first word typed after the script name, if it isn't
# an option like --save. Otherwise, default to the pattern flight's log.
args = [a for a in sys.argv[1:] if not a.startswith("--")]
LOG_FILE = args[0] if args else "pattern_log.csv"
SAVE_GIF = "--save" in sys.argv      # True if you typed --save

PLAYBACK_SPEED = 4     # 4 = replay four times faster than real time
FRAME_MS = 50          # time between animation frames (50 ms = 20 frames/sec)
TRAIL_ONLY = False     # True = draw the path only as the drone flies it

# One color per flight phase, from a colorblind-checked palette. The phase
# names are also in the legend and the on-screen readout, so color is never
# the only way to tell phases apart.
PHASE_COLORS = {
    "climb": "#2a78d6",     # blue
    "pattern": "#eb6834",   # orange
    "follow": "#eb6834",    # (follow_sim.py's middle phase; same slot)
    "hover": "#eb6834",     # (first_flight.py's middle phase; same slot)
    "land": "#1baf7a",      # aqua
}
SURFACE = "#fcfcfb"         # chart background
INK = "#1a1a19"             # main text
INK_MUTED = "#6b6a63"       # axis labels, gridlines
TARGET_COLOR = "#8a4fd6"    # purple: the fake target (follow_sim.py logs only)


# ---------------------------------------------------------------------------
# 1. READ THE LOG
# ---------------------------------------------------------------------------
# csv.DictReader turns each row into a dictionary keyed by the column
# headers, e.g. row["alt_m"]. Everything arrives as text, so we convert
# numbers with float().
with open(LOG_FILE, newline="") as f:
    rows = list(csv.DictReader(f))

if not rows:
    raise SystemExit(f"{LOG_FILE} has no data rows.")

times = [float(r["time_s"]) for r in rows]
alts = [float(r["alt_m"]) for r in rows]
phases = [r["phase"] for r in rows]

# North/east in meters. pattern_log.csv has them directly. altitude_log.csv
# (from first_flight.py) only has latitude/longitude, so we convert: one
# degree of latitude is about 111,320 m everywhere, and one degree of
# longitude shrinks by cos(latitude) as you move away from the equator.
# This "flat Earth" approximation is very accurate over a few hundred meters.
if "north_m" in rows[0] and rows[0]["north_m"] != "":
    # Blank cells (no local position yet) are filled with the previous value.
    norths, easts = [], []
    last_n, last_e = 0.0, 0.0
    for r in rows:
        last_n = float(r["north_m"]) if r["north_m"] != "" else last_n
        last_e = float(r["east_m"]) if r["east_m"] != "" else last_e
        norths.append(last_n)
        easts.append(last_e)
else:
    lat0, lon0 = float(rows[0]["lat_deg"]), float(rows[0]["lon_deg"])
    meters_per_deg = 111_320
    norths = [(float(r["lat_deg"]) - lat0) * meters_per_deg for r in rows]
    easts = [(float(r["lon_deg"]) - lon0) * meters_per_deg * math.cos(math.radians(lat0))
             for r in rows]
# Target path (follow_sim.py logs only). Its cells are blank outside the
# follow phase, so keep just the rows that have a target position.
target_rows = [i for i, r in enumerate(rows) if r.get("target_n", "") != ""]
target_norths = [float(rows[i]["target_n"]) for i in target_rows]
target_easts = [float(rows[i]["target_e"]) for i in target_rows]

print(f"Loaded {len(rows)} rows from {LOG_FILE} ({times[-1]:.1f} s of flight)")


# ---------------------------------------------------------------------------
# 2. SET UP THE 3D PLOT
# ---------------------------------------------------------------------------
fig = plt.figure(figsize=(9, 7), facecolor=SURFACE)
ax = fig.add_subplot(projection="3d", facecolor=SURFACE)

# Axes: x = east, y = north, z = altitude. That way "up" on the ground plane
# is north, like a map.
ax.set_xlabel("East of home (m)", color=INK_MUTED, labelpad=8)
ax.set_ylabel("North of home (m)", color=INK_MUTED, labelpad=8)
ax.set_zlabel("Altitude (m)", color=INK_MUTED, labelpad=8)
ax.tick_params(colors=INK_MUTED, labelsize=8)
for axis in (ax.xaxis, ax.yaxis, ax.zaxis):
    axis.pane.set_facecolor(SURFACE)        # plain background panes
    axis.pane.set_edgecolor("#e4e3dc")
    axis._axinfo["grid"]["color"] = "#ecebe5"   # light, recessive gridlines

# Fit the axes to the data with a small margin, and keep meters equal in
# every direction so a square looks square (not stretched).
pad = 2
x_lo, x_hi = min(easts + target_easts) - pad, max(easts + target_easts) + pad
y_lo, y_hi = min(norths + target_norths) - pad, max(norths + target_norths) + pad
z_lo, z_hi = 0, max(alts) + pad
ax.set_xlim(x_lo, x_hi)
ax.set_ylim(y_lo, y_hi)
ax.set_zlim(z_lo, z_hi)
ax.set_box_aspect((x_hi - x_lo, y_hi - y_lo, z_hi - z_lo))

ax.set_title(f"Flight replay: {LOG_FILE}", color=INK, fontsize=12, pad=12)

# Home marker on the ground, where the flight started.
ax.scatter([easts[0]], [norths[0]], [0], s=60, marker="^",
           color=INK_MUTED, depthshade=False)
ax.text(easts[0], norths[0], -0.8, "home", color=INK_MUTED, fontsize=8)

# One line per phase. They start empty and grow as the animation plays.
# (If TRAIL_ONLY is False, a faint copy of the full path is drawn first,
# so you can see where the drone is headed.)
phase_order = [p for p in ["climb", "hover", "pattern", "follow", "land"] if p in phases]
lines = {}
for ph in phase_order:
    color = PHASE_COLORS.get(ph, INK_MUTED)
    if not TRAIL_ONLY:
        idx = [i for i, p in enumerate(phases) if p == ph]
        ax.plot([easts[i] for i in idx], [norths[i] for i in idx],
                [alts[i] for i in idx], color=color, alpha=0.18, linewidth=1.5)
    (lines[ph],) = ax.plot([], [], [], color=color, linewidth=2, label=ph)

# Ground shadow: the path projected straight down, which makes the 3D
# shape much easier to read.
(shadow,) = ax.plot([], [], [], color="#c9c8c0", linewidth=1, linestyle="--")

# The drone itself, and a vertical line down to its shadow.
(drone,) = ax.plot([], [], [], marker="o", markersize=9, color=INK,
                   markeredgecolor=SURFACE, markeredgewidth=2, linestyle="")
(drop_line,) = ax.plot([], [], [], color=INK_MUTED, linewidth=0.8, alpha=0.6)

# Target: its full path on the ground (faint), a moving star, and a sight
# line from the drone to the target.
if target_rows:
    ax.plot(target_easts, target_norths, [0] * len(target_rows),
            color=TARGET_COLOR, alpha=0.35, linewidth=1.5, label="target path")
(target_dot,) = ax.plot([], [], [], marker="*", markersize=14, color=TARGET_COLOR,
                        linestyle="")
(sight_line,) = ax.plot([], [], [], color=TARGET_COLOR, linewidth=0.8, alpha=0.7)

ax.legend(loc="upper left", frameon=False, labelcolor=INK, fontsize=9)

# On-screen readout, updated every frame.
readout = fig.text(0.02, 0.03, "", color=INK, fontsize=10, family="monospace")


# ---------------------------------------------------------------------------
# 3. ANIMATE
# ---------------------------------------------------------------------------
# Pick which log rows to show in each animation frame. With PLAYBACK_SPEED 4
# and 50 ms frames, each frame advances 0.2 s of flight time.
frame_times = []
t = 0.0
while t <= times[-1]:
    frame_times.append(t)
    t += PLAYBACK_SPEED * FRAME_MS / 1000
frame_times.append(times[-1])   # always end exactly on the last row


def row_at(t_target):
    """Index of the last log row at or before a given time."""
    i = 0
    while i + 1 < len(times) and times[i + 1] <= t_target:
        i += 1
    return i


def update(frame_number):
    """Draw one frame. FuncAnimation calls this over and over."""
    i = row_at(frame_times[frame_number])   # show rows 0..i

    # Grow each phase's line up to row i.
    for ph, line in lines.items():
        idx = [j for j in range(i + 1) if phases[j] == ph]
        line.set_data_3d([easts[j] for j in idx], [norths[j] for j in idx],
                         [alts[j] for j in idx])

    shadow.set_data_3d(easts[: i + 1], norths[: i + 1], [0] * (i + 1))
    drone.set_data_3d([easts[i]], [norths[i]], [alts[i]])
    drop_line.set_data_3d([easts[i], easts[i]], [norths[i], norths[i]], [0, alts[i]])

    # Target star and sight line: only on rows that have a target position.
    r = rows[i]
    if r.get("target_n", "") != "":
        tn, te = float(r["target_n"]), float(r["target_e"])
        target_dot.set_data_3d([te], [tn], [0])
        sight_line.set_data_3d([easts[i], te], [norths[i], tn], [alts[i], 0])
        follow_txt = f"   range {float(r['range_m']):4.1f} m   bearing {float(r['bearing_deg']):+5.1f} deg"
    else:
        target_dot.set_data_3d([], [], [])
        sight_line.set_data_3d([], [], [])
        follow_txt = ""

    readout.set_text(f"t {times[i]:5.1f} s   alt {alts[i]:5.1f} m   "
                     f"N {norths[i]:6.1f} m   E {easts[i]:6.1f} m   phase: {phases[i]}"
                     + follow_txt)

    # Slowly rotate the camera: the viewing angle (azimuth) sweeps from -70
    # to -30 degrees over the replay, which keeps the 3D shape easy to read.
    ax.view_init(elev=25, azim=-70 + 40 * frame_number / len(frame_times))
    return list(lines.values()) + [shadow, drone, drop_line, readout, target_dot, sight_line]


anim = FuncAnimation(fig, update, frames=len(frame_times),
                     interval=FRAME_MS, blit=False, repeat=True)

if SAVE_GIF:
    print("Saving flight_3d.gif (this takes a little while) ...")
    # dpi=80 keeps the file size reasonable for sharing.
    anim.save("flight_3d.gif", writer=PillowWriter(fps=1000 // FRAME_MS), dpi=80)
    print("Saved flight_3d.gif")

plt.show()
