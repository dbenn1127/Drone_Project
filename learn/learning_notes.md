# Learning notes

Short write-ups after each learning-plan exercise, in my own words.

## 2026-10-05 — Module 0, exercises 1–5 (learn/warmup.py)

**1. Range and bearing.** `math.hypot` gives the straight-line range and `math.atan2(de, dn)` gives the bearing from north; the argument order is east first, north second. For a prediction I only need a bound: 3 north, 4 east is more east than north, so the angle is between 45° and 90°. Swapping the arguments gives ~37°, which the bound catches.

**2. Timed loop.** Why did 30 passes of `sleep(0.1)` end at 2.92 s instead of 3.00? What does that mean for a 10 Hz control loop?
-because the next iteration is greater than 3.0 due to the added processing time of the rest of the code.
-its not exact as-is

**2b. How follow_sim.py gets its 10 Hz.** No `sleep`. What paces the loop instead, and what parameter on the real flight controller sets that rate?
-The position message

**3. Exception handlers.** Why does `follow_sim.py` need both `except KeyboardInterrupt` and `except Exception`? Does the order of the two matter?
-except Excception does not cover ctrl+c and would kill script and leave drone hovering with no land command
-order does not matter

**4. sys.argv.** What is at index 0? Why does `len(sys.argv) > 1` need to be checked before using `sys.argv[1]`?
-the name of the script
-to avoid exception error

**5. Functions as values and dictionaries.** What does `target = TEST[test_name]` store? Why does the "unknown test" check have to come before that line?
-the function that the script runs
-because it will throw an error for not having the test in the dictionary

**Thing I found reading the code.** The follow loop reads the flight mode from every heartbeat but only prints it; it doesn't stop commanding if the mode leaves GUIDED. Monitored is not the same as acted on.