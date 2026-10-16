# Follow-Me Drone — Concept of Operations (ConOps) v0.3

Step 1 of the model rebuild (needs + ConOps). Written from Derek's answers, 2026-10-16. Plain English; no design detail beyond what the operator sees.

## Mission
Film a person on foot, hands-free, by autonomously following them from an operator-chosen distance and angle relative to their direction of travel.

## Stakeholders
- **Operator/pilot**: runs the ground station and holds the RC as backup.
- **Target**: the person being filmed.
- **Bystanders**: people nearby who are not part of the flight.
- **FAA**: rules for recreational flight.

## Assumptions
- **A-1**: Two-person operation: one operator/pilot plus the target. Solo operation is a possible future goal, not designed for now.
- **A-2**: Notional mission is filming (chosen 2026-10-16) for a portfolio project.

## Normal flight
1. **Launch**: operator commands Launch at the ground station; the flight controller takes off autonomously and hovers. The RC is a backup only.
2. **Search**: if no person is in view, the gimbal sweeps. If it still finds nothing, the drone rotates in place.
3. **Propose**: the system proposes a person (for example, the nearest). The operator approves, or clicks a different person instead.
4. **Follow**: approval starts the follow. The drone holds the configured offset; the gimbal keeps the target centred.
   - Offset is relative to the target's **direction of travel**, not the way they face (walking backwards puts "behind" in front of them).
   - When the target stands still, the drone keeps its current position until they move again.
   - Defaults: **8 m**, **180° (behind)**, **10 m height (fixed for now)**. Distance limits **5–20 m**; angle any.
   - Operator can change distance and angle **mid-flight**; the drone moves to the new position gradually and never inside the 5 m keep-out zone.
5. **Target lost**: the drone holds position, the gimbal searches, and the system re-proposes when a person is found. The operator approves to resume. **The follow never ends on its own.**
6. **Ending**: the operator can command **stop and hover**, **land here**, or **return to launch (RTL)**. The pilot can **take over at any time** by switching out of GUIDED. Failsafes (battery, link loss, geofence) can also end the flight.

## Open items
- Search time limits (how long before giving up or alerting).
- Behaviour while drone rotates during search near obstacles/bystanders.
- Exact angle/distance change rate mid-flight.
