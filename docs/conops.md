# Tandem — Concept of Operations (ConOps) v1.0

Step 1 of the model rebuild (needs + ConOps). Written from Derek's answers, 2026-10-16. v0.4 (2026-10-19): product named Tandem; mission reframed from filming to a capability with a human in the loop. v0.5 (2026-10-19): added A-3 (launch site clear) and search-finds-no-one behaviour; height 10 m → 6 m [TBR] (better camera angle for detection; equals launch altitude). v0.6 (2026-10-19): target beyond 20 m = lost (superseded in v0.8); crossing/overlap → hold and re-confirm. v0.7 (2026-10-19): framing zone instead of a fixed point; distance, angle, zone width and height all configurable; black-box wording (no internal parts). v0.8 (2026-10-19): 'lost' = not seen for 2 s (distance is no longer a lost trigger); falling behind is alerted, not dropped. v0.9 (2026-10-19): overlap returns to target acquisition (proposal = best guess of the previous target). v1.0 (2026-10-25): added Prepare for flight (prechecks incl. RC link; settings confirmed before arming). Plain English; no design detail beyond what the operator sees.v1.1 (2026-10-26): A-6 (no sensing outside camera view; bystanders are the operator's responsibility); keep-out zone is never entered by Tandem, target may walk in (drone holds).

## Mission
Keep a person the operator chooses in view and follow them from an operator-chosen distance and angle relative to their direction of travel, with the operator approving every target decision.

Example applications: filming a person on foot, overwatch for a hiker or runner, search-and-rescue support.

## Stakeholders
- **Operator/pilot**: runs the ground station and holds the RC as backup.
- **Target**: the person the operator designates.
- **Bystanders**: people nearby who are not part of the flight.
- **FAA**: rules for recreational flight.

## Assumptions
- **A-1**: Two-person operation: one operator/pilot plus the target. Solo operation is a possible future goal, not designed for now.
- **A-2**: Mission is capability-first (person tracking and following with a human approving every designation); filming is one example application, not the goal. Revised 2026-10-19 from the earlier notional filming mission.
- **A-3**: The launch site is clear overhead and around the drone. Tandem has no obstacle sensing; this is the operator's responsibility.
- **A-4**: The landing area is clear of people and obstacles. Tandem only sees beneath it during descent; the operator confirms the spot.
- **A-5**: Tandem is flown in open areas with no obstacles above 6 m [TBR] (the return altitude).
- **A-6**: Tandem does not sense people or obstacles outside the camera view. The operator flies only where bystanders are sparse and keeps the drone clear of them, taking over if needed.

## Normal flight
0. **Prepare**: operator powers on the drone, ground station and RC. Tandem runs its prechecks (ground link, RC link, GPS, camera, battery, flight-safety checks) and reports ready only when all pass, showing anything that fails. Tandem shows the follow settings (left over from the last flight, or defaults); the operator changes them if needed and confirms. Only then can the operator arm.
1. **Launch**: operator commands Launch at the ground station; Tandem takes off autonomously and hovers at launch altitude. The RC is a backup only.
2. **Search**: if no person is in view, the camera sweeps. If it still finds nothing, the drone rotates in place. If a full scan finds no one, the operator is alerted and scanning continues.
3. **Propose**: the system proposes a person (for example, the nearest). The operator approves, or clicks a different person instead.
4. **Follow**: approval starts the follow. The drone stays within a **framing zone** around the configured offset and only moves when it drifts out of it; the camera keeps the target centred.
   - Offset is relative to the target's **direction of travel**, not the way they face (walking backwards puts "behind" in front of them).
   - When the target stands still, the drone keeps its current position until they move again.
   - Settings (all operator-configurable, also mid-flight; ranges [TBR]):
     | Setting | Default | Range |
     |---|---|---|
     | Distance | 8 m | 5–20 m |
     | Angle (centre of zone) | 180° (behind) | any |
     | Zone width | ±90° (rear half) | ±15° to ±180° (full circle) |
     | Height | 6 m (= launch altitude) | 3–15 m |
   - Combined camera-to-target distance √(distance² + height²) must not exceed 20 m (detection limit); combinations that break it are not accepted.
   - Rear half is the default because the space behind the person is ground they just walked through, and they never walk toward the drone.
   - Operator can change the settings **mid-flight**; the drone moves to the new position gradually and never inside the 5 m keep-out zone.
   - If the target outruns the drone, it keeps chasing at top speed and the operator is told it is falling behind. The target is only treated as lost when it is no longer seen (step 5); distance alone never drops a well-tracked target.
   - If another person overlaps the target in view, Tandem returns to target acquisition: the drone holds, and Tandem proposes its best guess of who the target was for the operator to approve (or the operator picks someone else). Tandem cannot detect an identity swap itself, so it guards the situation where swaps happen.
5. **Target lost** (not seen for 2 s [TBR]): the operator is alerted, the drone holds position, the camera searches, and the system re-proposes when a person is found. The operator approves to resume. **The follow never ends on its own.**
6. **Ending**: the operator can command **stop and hover**, **land here**, or **return to launch (RTL)**. The pilot can **take over at any time** by selecting manual control on the RC. Failsafes (battery, link loss, geofence) can also end the flight.

## Open items
- Behaviour while drone rotates during search near obstacles/bystanders.
- Exact angle/distance change rate mid-flight.